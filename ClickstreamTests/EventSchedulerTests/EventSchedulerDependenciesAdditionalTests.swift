//
//  EventSchedulerDependenciesAdditionalTests.swift
//  ClickstreamTests
//
//  Created by Rishab Habbu on 29/05/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

/// Additional coverage for `EventSchedulerDependencies` focused on the Courier
/// branch (warehouser wiring with / without TTL configuration).
final class EventSchedulerDependenciesAdditionalTests: XCTestCase {

    private var networkOptions: ClickstreamNetworkOptions!
    private var database: DefaultDatabase!
    private var mockQueue: SerialQueue!
    private var dbQueueMock: SerialQueue!
    private var config: DefaultNetworkConfiguration!
    private var socketNetworkBuilder: WebsocketNetworkBuilder!
    private var courierNetworkBuilder: CourierNetworkBuilder!

    override func setUp() {
        super.setUp()
        Clickstream.configurations = MockConstants.constraints
        Clickstream.courierConfigurations = MockConstants.courierConstraints

        networkOptions = ClickstreamNetworkOptions()
        database = try! DefaultDatabase(qos: .WAL)
        mockQueue = SerialQueue(label: "com.test.esda.queue", qos: .utility)
        dbQueueMock = SerialQueue(label: "com.test.esda.dao", qos: .utility, attributes: .concurrent)
        config = DefaultNetworkConfiguration(request: URLRequest(url: URL(string: "ws://mock.clickstream.com")!))

        let socketService = WebsocketNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: mockQueue)
        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let socketPersistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAlive = DefaultKeepAliveServiceWithSafeTimer(with: mockQueue,
                                                              duration: 2,
                                                              reachability: NetworkReachabilityMock(isReachable: true))
        let socketRetry = WebsocketRetryMechanism(networkService: socketService,
                                                  reachability: NetworkReachabilityMock(isReachable: true),
                                                  deviceStatus: deviceStatus,
                                                  appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
                                                  performOnQueue: mockQueue,
                                                  persistence: socketPersistence,
                                                  keepAliveService: keepAlive)
        socketNetworkBuilder = WebsocketNetworkBuilder(networkConfigs: config,
                                                       retryMech: socketRetry,
                                                       performOnQueue: mockQueue)

        let courierService = CourierNetworkService<DefaultCourierHandler>(with: config, performOnQueue: mockQueue)
        let courierPersistence = DefaultDatabaseDAO<CourierEventRequest>(database: database, performOnQueue: dbQueueMock)
        let courierRetry = CourierRetryMechanism(networkOptions: networkOptions,
                                                 networkService: courierService,
                                                 reachability: NetworkReachabilityMock(isReachable: true),
                                                 appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
                                                 performOnQueue: mockQueue,
                                                 persistence: courierPersistence)
        courierNetworkBuilder = CourierNetworkBuilder(networkConfigs: config,
                                                     retryMech: courierRetry,
                                                     performOnQueue: mockQueue)
    }

    override func tearDown() {
        socketNetworkBuilder = nil
        courierNetworkBuilder = nil
        config = nil
        dbQueueMock = nil
        mockQueue = nil
        database = nil
        networkOptions = nil
        super.tearDown()
    }

    private func makeDeps() -> EventSchedulerDependencies {
        EventSchedulerDependencies(socketNetworkBuider: socketNetworkBuilder,
                                   courierNetworkBuider: courierNetworkBuilder,
                                   db: database,
                                   networkOptions: networkOptions)
    }

    func testMakeCourierWarehouser_withoutTTLConfig_returnsUsableInstance() {
        Clickstream.courierConfigurations = MockConstants.courierConstraints
        let deps = makeDeps()
        let warehouser = deps.makeCourierEventWarehouser()
        XCTAssertNotNil(warehouser)
        warehouser.stop()
    }

    func testMakeCourierWarehouser_withTTLConfig_returnsUsableInstance() throws {
        let payload: [String: Any] = [
            "is_ttl_enabled": true,
            "default_expiry_days": 5,
            "minimum_expiry_days": 1,
            "events_ttl": [:],
            "is_ttl_cleanup_enabled": true,
            "ttl_cleanup_interval_in_min": 60,
            "ttl_periodic_backOff_policy": "NONE",
            "ttl_periodic_backOff_delay_in_min": 0
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let expiry = try JSONDecoder().decode(EventExpirationConfig.self, from: data)

        var courierConstraints = MockConstants.courierConstraints
        courierConstraints.time_to_live = expiry
        Clickstream.courierConfigurations = courierConstraints

        let deps = makeDeps()
        let warehouser = deps.makeCourierEventWarehouser()
        XCTAssertNotNil(warehouser)
        warehouser.stop()

        // Restore so subsequent tests get a clean slate.
        Clickstream.courierConfigurations = MockConstants.courierConstraints
    }

    func testMakeSocketAndCourierWarehouserShareSameDatabase() {
        let deps = makeDeps()

        let socketWarehouser = deps.makeEventWarehouser()
        let courierWarehouser = deps.makeCourierEventWarehouser()

        XCTAssertNotNil(socketWarehouser)
        XCTAssertNotNil(courierWarehouser)
        courierWarehouser.stop()
    }
}
