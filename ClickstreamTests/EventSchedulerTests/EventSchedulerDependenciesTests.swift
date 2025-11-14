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

    private var database: DefaultDatabase!
    private var dbQueueMock: SerialQueue!
    private var mockQueue: SerialQueue!
    private var realTimeEvent: Event!
    private var config: DefaultNetworkConfiguration!
    private var networkService: DefaultNetworkService<SocketHandlerMockSuccess>!
    private var deviceStatus: DefaultDeviceStatus!
    private var persistence: DefaultDatabaseDAO<EventRequest>!
    private var keepAliveService: DefaultKeepAliveServiceWithSafeTimer!
    private var retryMech: DefaultRetryMechanism!
    private var networkBuildable: (any NetworkBuildable)!
    
    override func setUp() {
        super.setUp()
        
        database = try! DefaultDatabase(qos: .WAL)
        dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
        mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        realTimeEvent = Event(guid: "test-guid", timestamp: Date(), type: "realTime", eventProtoData: Data())
        
        guard let url = URL(string: "ws://mock.clickstream.com") else {
            XCTFail("Failed to create test URL")
            return
        }
        config = DefaultNetworkConfiguration(request: URLRequest(url: url))
        
        networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: mockQueue)
        deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        keepAliveService = DefaultKeepAliveServiceWithSafeTimer(
            with: mockQueue,
            duration: 2,
            reachability: NetworkReachabilityMock(isReachable: true)
        )
        retryMech = DefaultRetryMechanism(
            networkService: networkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: persistence,
            keepAliveService: keepAliveService
        )
        
        networkBuildable = DefaultNetworkBuilder(
            networkConfigs: config,
            retryMech: retryMech,
            performOnQueue: mockQueue
        )
    }
    
    override func tearDown() {
        database = nil
        dbQueueMock = nil
        mockQueue = nil
        realTimeEvent = nil
        config = nil
        networkService = nil
        deviceStatus = nil
        persistence = nil
        keepAliveService = nil
        retryMech = nil
        networkBuildable = nil
        super.tearDown()
    }
    
    func testInitialization() {
        let schedulerDependencies = EventSchedulerDependencies(with: networkBuildable, db: database)
        
        XCTAssertNotNil(schedulerDependencies)
    }
    
    func testMakeEventWarehouser() {
        let schedulerDependencies = EventSchedulerDependencies(with: networkBuildable, db: database)
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testMultipleEventWarehouserInstances() {
        let schedulerDependencies = EventSchedulerDependencies(with: networkBuildable, db: database)
        
        let warehouser1 = schedulerDependencies.makeEventWarehouser()
        let warehouser2 = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(warehouser1)
        XCTAssertNotNil(warehouser2)
        XCTAssertFalse(warehouser1 === warehouser2)
    }
    
    func testEventWarehouseWithDifferentNetworkConfigs() {
        guard let alternativeUrl = URL(string: "ws://alternative.clickstream.com") else {
            XCTFail("Failed to create alternative URL")
            return
        }
        
        let alternativeConfig = DefaultNetworkConfiguration(request: URLRequest(url: alternativeUrl))
        let alternativeNetworkService = DefaultNetworkService<SocketHandlerMockSuccess>(
            with: alternativeConfig,
            performOnQueue: mockQueue
        )
        let alternativeRetryMech = DefaultRetryMechanism(
            networkService: alternativeNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: persistence,
            keepAliveService: keepAliveService
        )
        let alternativeNetworkBuildable = DefaultNetworkBuilder(
            networkConfigs: alternativeConfig,
            retryMech: alternativeRetryMech,
            performOnQueue: mockQueue
        )
        
        let schedulerDependencies = EventSchedulerDependencies(
            with: alternativeNetworkBuildable,
            db: database
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithDifferentDatabase() {
        let alternativeDatabase = try! DefaultDatabase(qos: .WAL)
        
        let schedulerDependencies = EventSchedulerDependencies(
            with: networkBuildable,
            db: alternativeDatabase
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithUnreachableNetwork() {
        let unreachableRetryMech = DefaultRetryMechanism(
            networkService: networkService,
            reachability: NetworkReachabilityMock(isReachable: false),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: persistence,
            keepAliveService: keepAliveService
        )
        let unreachableNetworkBuildable = DefaultNetworkBuilder(
            networkConfigs: config,
            retryMech: unreachableRetryMech,
            performOnQueue: mockQueue
        )
        
        let schedulerDependencies = EventSchedulerDependencies(
            with: unreachableNetworkBuildable,
            db: database
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithInactiveAppState() {
        let inactiveRetryMech = DefaultRetryMechanism(
            networkService: networkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didEnterBackground),
            performOnQueue: mockQueue,
            persistence: persistence,
            keepAliveService: keepAliveService
        )
        let inactiveNetworkBuildable = DefaultNetworkBuilder(
            networkConfigs: config,
            retryMech: inactiveRetryMech,
            performOnQueue: mockQueue
        )
        
        let schedulerDependencies = EventSchedulerDependencies(
            with: inactiveNetworkBuildable,
            db: database
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
        let customRetryMech = DefaultRetryMechanism(
            networkService: networkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: persistence,
            keepAliveService: customKeepAliveService
        )
        let customNetworkBuildable = DefaultNetworkBuilder(
            networkConfigs: config,
            retryMech: customRetryMech,
            performOnQueue: mockQueue
        )
        
        let schedulerDependencies = EventSchedulerDependencies(
            with: customNetworkBuildable,
            db: database
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
    
    func testEventWarehouseWithHighPriorityQueue() {
        let highPriorityQueue = SerialQueue(label: "com.test.high.priority", qos: .userInitiated)
        let highPriorityNetworkService = DefaultNetworkService<SocketHandlerMockSuccess>(
            with: config,
            performOnQueue: highPriorityQueue
        )
        let highPriorityRetryMech = DefaultRetryMechanism(
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
        let highPriorityNetworkBuildable = DefaultNetworkBuilder(
            networkConfigs: config,
            retryMech: highPriorityRetryMech,
            performOnQueue: highPriorityQueue
        )
        
        let schedulerDependencies = EventSchedulerDependencies(
            with: highPriorityNetworkBuildable,
            db: database
        )
        
        let eventWarehouser = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(eventWarehouser)
    }
}
