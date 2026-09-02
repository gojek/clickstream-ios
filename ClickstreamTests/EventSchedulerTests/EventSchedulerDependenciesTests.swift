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
    private var realTimeEvent: CourierEvent!
    private var config: DefaultNetworkConfiguration!

    private var courierNetworkService: CourierNetworkService<DefaultCourierHandler>!
    private var courierPersistence: DefaultDatabaseDAO<CourierEventRequest>!
    private var courierRetryMech: CourierRetryMechanism!
    private var courierNetworkBuilder: CourierNetworkBuilder!

    override func setUp() {
        super.setUp()
        
        networkOptions = ClickstreamNetworkOptions()
        database = try! DefaultDatabase(qos: .WAL)
        dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
        mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        realTimeEvent = CourierEvent(guid: "test-guid", timestamp: Date(), type: "realTime", eventProtoData: Data(), expiryTime: Date())
        
        guard let url = URL(string: "https://mock.clickstream.com") else {
            XCTFail("Failed to create test URL")
            return
        }
        config = DefaultNetworkConfiguration(request: URLRequest(url: url))
        
        courierNetworkService = CourierNetworkService<DefaultCourierHandler>(with: config, performOnQueue: mockQueue)
        courierPersistence = DefaultDatabaseDAO<CourierEventRequest>(database: database, performOnQueue: dbQueueMock)

        courierRetryMech = CourierRetryMechanism(
            networkOptions: networkOptions,
            networkService: courierNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: courierPersistence
        )
        
        courierNetworkBuilder = CourierNetworkBuilder(
            networkConfigs: config,
            retryMech: courierRetryMech,
            retryMechV2: nil,
            performOnQueue: mockQueue
        )
    }
    
    override func tearDown() {
        database = nil
        dbQueueMock = nil
        mockQueue = nil
        realTimeEvent = nil
        config = nil
        courierNetworkService = nil
        courierPersistence = nil
        courierRetryMech = nil
        courierNetworkBuilder = nil
        super.tearDown()
    }
    
    private func makeDependencies(networkBuilder: (any NetworkBuildable)? = nil) -> EventSchedulerDependencies {
        EventSchedulerDependencies(
            courierNetworkBuider: networkBuilder ?? courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        )
    }
    
    func testInitialization() {
        let schedulerDependencies = makeDependencies()
        
        XCTAssertNotNil(schedulerDependencies)
    }
    
    func testMakeCourierEventWarehouser() {
        let schedulerDependencies = makeDependencies()
        
        let courierEventWarehouser = schedulerDependencies.makeCourierEventWarehouser()

        XCTAssertNotNil(courierEventWarehouser)
    }
    
    func testMultipleEventWarehouserInstances() {
        let schedulerDependencies = makeDependencies()

        let courierEventWarehouser1 = schedulerDependencies.makeCourierEventWarehouser()
        let courierEventWarehouser2 = schedulerDependencies.makeCourierEventWarehouser()

        XCTAssertNotNil(courierEventWarehouser1)
        XCTAssertNotNil(courierEventWarehouser2)
    }
    
    func testEventWarehouseWithDifferentDatabase() {
        let alternativeDatabase = try! DefaultDatabase(qos: .WAL)
        
        let schedulerDependencies = EventSchedulerDependencies(
            courierNetworkBuider: courierNetworkBuilder,
            db: alternativeDatabase,
            networkOptions: networkOptions
        )
        
        let eventWarehouser = schedulerDependencies.makeCourierEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithUnreachableNetwork() {
        let unreachableRetryMech = CourierRetryMechanism(
            networkOptions: networkOptions,
            networkService: courierNetworkService,
            reachability: NetworkReachabilityMock(isReachable: false),
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: courierPersistence
        )
        let unreachableNetworkBuildable = CourierNetworkBuilder(
            networkConfigs: config,
            retryMech: unreachableRetryMech,
            retryMechV2: nil,
            performOnQueue: mockQueue
        )
        
        let schedulerDependencies = makeDependencies(networkBuilder: unreachableNetworkBuildable)
        
        let eventWarehouser = schedulerDependencies.makeCourierEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithInactiveAppState() {
        let inactiveRetryMech = CourierRetryMechanism(
            networkOptions: networkOptions,
            networkService: courierNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            appStateNotifier: AppStateNotifierMock(state: .didEnterBackground),
            performOnQueue: mockQueue,
            persistence: courierPersistence
        )
        let inactiveNetworkBuildable = CourierNetworkBuilder(
            networkConfigs: config,
            retryMech: inactiveRetryMech,
            retryMechV2: nil,
            performOnQueue: mockQueue
        )
        
        let schedulerDependencies = makeDependencies(networkBuilder: inactiveNetworkBuildable)
        
        let eventWarehouser = schedulerDependencies.makeCourierEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithHighPriorityQueue() {
        let highPriorityQueue = SerialQueue(label: "com.test.high.priority", qos: .userInitiated)
        let highPriorityNetworkService = CourierNetworkService<DefaultCourierHandler>(
            with: config,
            performOnQueue: highPriorityQueue
        )
        let highPriorityRetryMech = CourierRetryMechanism(
            networkOptions: networkOptions,
            networkService: highPriorityNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: highPriorityQueue,
            persistence: DefaultDatabaseDAO<CourierEventRequest>(database: database, performOnQueue: highPriorityQueue)
        )
        let highPriorityNetworkBuildable = CourierNetworkBuilder(
            networkConfigs: config,
            retryMech: highPriorityRetryMech,
            retryMechV2: nil,
            performOnQueue: highPriorityQueue
        )
        
        let schedulerDependencies = makeDependencies(networkBuilder: highPriorityNetworkBuildable)
        
        let eventWarehouser = schedulerDependencies.makeCourierEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
}
