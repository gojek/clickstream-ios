//
//  EventSchedulerDependenciesTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 29/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class EventSchedulerDependenciesTests: XCTestCase {

    private var networkOptions: ClickstreamNetworkOptions!
    private var database: DefaultDatabase!
    private var dbQueueMock: SerialQueue!
    private var mockQueue: SerialQueue!
    private var realTimeEvent: Event!
    private var config: DefaultNetworkConfiguration!

    private var socketNetworkService: WebsocketNetworkService<SocketHandlerMockSuccess>!
    private var courierNetworkService: CourierNetworkService<DefaultCourierHandler>!

    private var deviceStatus: DefaultDeviceStatus!
    
    private var socketPersistence: DefaultDatabaseDAO<EventRequest>!
    private var courierPersistence: DefaultDatabaseDAO<CourierEventRequest>!

    private var keepAliveService: DefaultKeepAliveServiceWithSafeTimer!

    private var socketRetryMech: WebsocketRetryMechanism!
    private var courierRetryMech: CourierRetryMechanism!

    private var socketNetworkBuilder: WebsocketNetworkBuilder!
    private var courierNetworkBuilder: CourierNetworkBuilder!

    override func setUp() {
        super.setUp()
        
        networkOptions = ClickstreamNetworkOptions()
        database = try! DefaultDatabase(qos: .WAL)
        dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
        mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        realTimeEvent = Event(guid: "test-guid", timestamp: Date(), type: "realTime", eventProtoData: Data())
        
        guard let url = URL(string: "ws://mock.clickstream.com") else {
            XCTFail("Failed to create test URL")
            return
        }
        config = DefaultNetworkConfiguration(request: URLRequest(url: url))
        
        socketNetworkService = WebsocketNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: mockQueue)
        courierNetworkService = CourierNetworkService<DefaultCourierHandler>(with: config, performOnQueue: mockQueue)

        deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)

        socketPersistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        courierPersistence = DefaultDatabaseDAO<CourierEventRequest>(database: database, performOnQueue: dbQueueMock)

        keepAliveService = DefaultKeepAliveServiceWithSafeTimer(
            with: mockQueue,
            duration: 2,
            reachability: NetworkReachabilityMock(isReachable: true)
        )

        socketRetryMech = WebsocketRetryMechanism(
            networkService: socketNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: socketPersistence,
            keepAliveService: keepAliveService
        )
        
        courierRetryMech = CourierRetryMechanism(
            networkOptions: networkOptions,
            networkService: courierNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: courierPersistence
        )
        
        socketNetworkBuilder = WebsocketNetworkBuilder(
            networkConfigs: config,
            retryMech: socketRetryMech,
            performOnQueue: mockQueue
        )
        
        courierNetworkBuilder = CourierNetworkBuilder(
            networkConfigs: config,
            retryMech: courierRetryMech,
            performOnQueue: mockQueue
        )
    }
    
    override func tearDown() {
        database = nil
        dbQueueMock = nil
        mockQueue = nil
        realTimeEvent = nil
        config = nil
        socketNetworkService = nil
        deviceStatus = nil
        socketPersistence = nil
        keepAliveService = nil
        socketRetryMech = nil
        socketNetworkBuilder = nil
        courierNetworkBuilder = nil
        super.tearDown()
    }
    
    func testInitialization() {
        let schedulerDependencies = EventSchedulerDependencies(
            socketNetworkBuider: socketNetworkBuilder,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        )
        
        XCTAssertNotNil(schedulerDependencies)
    }
    
    func testMakeEventWarehouser() {
        let schedulerDependencies = EventSchedulerDependencies(
            socketNetworkBuider: socketNetworkBuilder,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        )
        
        let socketEventWarehouser = schedulerDependencies.makeEventWarehouser()
        let courierEventWarehouser = schedulerDependencies.makeCourierEventWarehouser()

        XCTAssertNotNil(socketEventWarehouser)
        XCTAssertNotNil(courierEventWarehouser)
    }
    
    func testMultipleEventWarehouserInstances() {
        let schedulerDependencies = EventSchedulerDependencies(
            socketNetworkBuider: socketNetworkBuilder,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        )

        let socketEventWarehouser1 = schedulerDependencies.makeEventWarehouser()
        let socketEventWarehouser2 = schedulerDependencies.makeEventWarehouser()

        let courierEventWarehouser1 = schedulerDependencies.makeCourierEventWarehouser()
        let courierEventWarehouser2 = schedulerDependencies.makeCourierEventWarehouser()

        XCTAssertNotNil(socketEventWarehouser1)
        XCTAssertNotNil(socketEventWarehouser2)

        XCTAssertNotNil(courierEventWarehouser1)
        XCTAssertNotNil(courierEventWarehouser2)
    }
    
    func testEventWarehouseWithDifferentNetworkConfigs() {
        guard let alternativeUrl = URL(string: "ws://alternative.clickstream.com") else {
            XCTFail("Failed to create alternative URL")
            return
        }
        
        let alternativeConfig = DefaultNetworkConfiguration(request: URLRequest(url: alternativeUrl))
        let alternativeNetworkService = WebsocketNetworkService<SocketHandlerMockSuccess>(
            with: alternativeConfig,
            performOnQueue: mockQueue
        )
        let alternativeRetryMech = WebsocketRetryMechanism(
            networkService: alternativeNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: socketPersistence,
            keepAliveService: keepAliveService
        )
        let alternativeNetworkBuildable = WebsocketNetworkBuilder(
            networkConfigs: alternativeConfig,
            retryMech: alternativeRetryMech,
            performOnQueue: mockQueue
        )
        
        let schedulerDependencies = EventSchedulerDependencies(
            socketNetworkBuider: socketNetworkBuilder,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithDifferentDatabase() {
        let alternativeDatabase = try! DefaultDatabase(qos: .WAL)
        
        let schedulerDependencies = EventSchedulerDependencies(
            socketNetworkBuider: socketNetworkBuilder,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithUnreachableNetwork() {
        let unreachableRetryMech = WebsocketRetryMechanism(
            networkService: socketNetworkService,
            reachability: NetworkReachabilityMock(isReachable: false),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: socketPersistence,
            keepAliveService: keepAliveService
        )
        let unreachableNetworkBuildable = WebsocketNetworkBuilder(
            networkConfigs: config,
            retryMech: unreachableRetryMech,
            performOnQueue: mockQueue
        )
        
        let schedulerDependencies = EventSchedulerDependencies(
            socketNetworkBuider: unreachableNetworkBuildable,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithInactiveAppState() {
        let inactiveRetryMech = WebsocketRetryMechanism(
            networkService: socketNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didEnterBackground),
            performOnQueue: mockQueue,
            persistence: socketPersistence,
            keepAliveService: keepAliveService
        )
        let inactiveNetworkBuildable = WebsocketNetworkBuilder(
            networkConfigs: config,
            retryMech: inactiveRetryMech,
            performOnQueue: mockQueue
        )
        
        let schedulerDependencies = EventSchedulerDependencies(
            socketNetworkBuider: inactiveNetworkBuildable,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithCustomKeepAliveSettings() {
        let customKeepAliveService = DefaultKeepAliveServiceWithSafeTimer(
            with: mockQueue,
            duration: 10,
            reachability: NetworkReachabilityMock(isReachable: true)
        )
        let customRetryMech = WebsocketRetryMechanism(
            networkService: socketNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: socketPersistence,
            keepAliveService: customKeepAliveService
        )
        let customNetworkBuildable = WebsocketNetworkBuilder(
            networkConfigs: config,
            retryMech: customRetryMech,
            performOnQueue: mockQueue
        )
        
        let schedulerDependencies = EventSchedulerDependencies(
            socketNetworkBuider: customNetworkBuildable,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithHighPriorityQueue() {
        let highPriorityQueue = SerialQueue(label: "com.test.high.priority", qos: .userInitiated)
        let highPriorityNetworkService = WebsocketNetworkService<SocketHandlerMockSuccess>(
            with: config,
            performOnQueue: highPriorityQueue
        )
        let highPriorityRetryMech = WebsocketRetryMechanism(
            networkService: highPriorityNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: DefaultDeviceStatus(performOnQueue: highPriorityQueue),
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: highPriorityQueue,
            persistence: DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: highPriorityQueue),
            keepAliveService: DefaultKeepAliveServiceWithSafeTimer(
                with: highPriorityQueue,
                duration: 2,
                reachability: NetworkReachabilityMock(isReachable: true)
            )
        )
        let highPriorityNetworkBuildable = WebsocketNetworkBuilder(
            networkConfigs: config,
            retryMech: highPriorityRetryMech,
            performOnQueue: highPriorityQueue
        )
        
        let schedulerDependencies = EventSchedulerDependencies(
            socketNetworkBuider: highPriorityNetworkBuildable,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
}
