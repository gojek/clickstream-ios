//
//  SharedEventSchedulerDependenciesTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 14/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class SharedEventSchedulerDependenciesTests: XCTestCase {

    private var database: DefaultDatabase!
    private var dbQueueMock: SerialQueue!
    private var mockQueue: SerialQueue!
    private var socketConfig: DefaultNetworkConfiguration!
    private var courierConfig: DefaultNetworkConfiguration!
    private var socketNetworkService: DefaultNetworkService<SocketHandlerMockSuccess>!
    private var courierNetworkService: DefaultNetworkService<SocketHandlerMockSuccess>!
    private var deviceStatus: DefaultDeviceStatus!
    private var socketPersistance: DefaultDatabaseDAO<EventRequest>!
    private var courierPersistance: DefaultDatabaseDAO<CourierEventRequest>!
    private var keepAliveService: DefaultKeepAliveServiceWithSafeTimer!
    private var socketRetryMech: DefaultRetryMechanism!
    private var courierRetryMech: CourierRetryMechanism!
    private var socketNetworkBuildable: (any NetworkBuildable)!
    private var courierNetworkBuildable: (any NetworkBuildable)!
    
    override func setUp() {
        super.setUp()
        
        database = try! DefaultDatabase(qos: .WAL)
        dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
        mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        
        guard let socketUrl = URL(string: "ws://socket.clickstream.com"),
              let courierUrl = URL(string: "ws://courier.clickstream.com") else {
            XCTFail("Failed to create test URLs")
            return
        }
        
        socketConfig = DefaultNetworkConfiguration(request: URLRequest(url: socketUrl))
        courierConfig = DefaultNetworkConfiguration(request: URLRequest(url: courierUrl))
        
        socketNetworkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: socketConfig, performOnQueue: mockQueue)
        courierNetworkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: courierConfig, performOnQueue: mockQueue)
        deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        socketPersistance = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        courierPersistance = DefaultDatabaseDAO<CourierEventRequest>(database: database, performOnQueue: dbQueueMock)
        keepAliveService = DefaultKeepAliveServiceWithSafeTimer(
            with: mockQueue,
            duration: 2,
            reachability: NetworkReachabilityMock(isReachable: true)
        )
        
        socketRetryMech = DefaultRetryMechanism(
            networkService: socketNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: socketPersistance,
            keepAliveService: keepAliveService
        )
        
        courierRetryMech = CourierRetryMechanism(
            networkOptions: .init(isWebsocketEnabled: false, isCourierEnabled: true),
            networkService: courierNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: courierPersistance
        )
        
        socketNetworkBuildable = DefaultNetworkBuilder(
            networkConfigs: socketConfig,
            retryMech: socketRetryMech,
            performOnQueue: mockQueue
        )
        
        courierNetworkBuildable = CourierNetworkBuilder(
            networkConfigs: courierConfig,
            retryMech: courierRetryMech,
            performOnQueue: mockQueue
        )
    }
    
    override func tearDown() {
        database = nil
        dbQueueMock = nil
        mockQueue = nil
        socketConfig = nil
        courierConfig = nil
        socketNetworkService = nil
        courierNetworkService = nil
        deviceStatus = nil
        socketPersistance = nil
        courierPersistance = nil
        keepAliveService = nil
        socketRetryMech = nil
        courierRetryMech = nil
        super.tearDown()
    }
    
    func testInitialization() {
        let sharedDependencies = SharedEventSchedulerDependencies(
            socketNetworkBuilder: socketNetworkBuildable,
            courierNetworkBuilder: courierNetworkBuildable,
            db: database
        )
        
        XCTAssertNotNil(sharedDependencies)
    }
    
    func testMakeSharedEventWarehouser() {
        let sharedDependencies = SharedEventSchedulerDependencies(
            socketNetworkBuilder: socketNetworkBuildable,
            courierNetworkBuilder: courierNetworkBuildable,
            db: database
        )
        
        let networkOptions = ClickstreamNetworkOptions()
        let sharedWarehouser = sharedDependencies.makeSharedEventWarehouser(with: networkOptions)
        
        XCTAssertNotNil(sharedWarehouser)
        XCTAssertTrue(sharedWarehouser is SharedEventWarehouser)
    }
    
    func testMakeSharedEventWarehouseWithSocketOnly() {
        let sharedDependencies = SharedEventSchedulerDependencies(
            socketNetworkBuilder: socketNetworkBuildable,
            courierNetworkBuilder: courierNetworkBuildable,
            db: database
        )
        
        let networkOptions = ClickstreamNetworkOptions()
        let sharedWarehouser = sharedDependencies.makeSharedEventWarehouser(with: networkOptions)
        
        XCTAssertNotNil(sharedWarehouser)
    }
    
    func testMakeSharedEventWarehouseWithCourierOnly() {
        let sharedDependencies = SharedEventSchedulerDependencies(
            socketNetworkBuilder: socketNetworkBuildable,
            courierNetworkBuilder: courierNetworkBuildable,
            db: database
        )
        
        let networkOptions = ClickstreamNetworkOptions(isWebsocketEnabled: false, isCourierEnabled: true)
        let sharedWarehouser = sharedDependencies.makeSharedEventWarehouser(with: networkOptions)
        
        XCTAssertNotNil(sharedWarehouser)
    }
    
    func testMakeSharedEventWarehouseWithDualNetworking() {
        let sharedDependencies = SharedEventSchedulerDependencies(
            socketNetworkBuilder: socketNetworkBuildable,
            courierNetworkBuilder: courierNetworkBuildable,
            db: database
        )
        
        let networkOptions = ClickstreamNetworkOptions(isWebsocketEnabled: true, isCourierEnabled: true)
        let sharedWarehouser = sharedDependencies.makeSharedEventWarehouser(with: networkOptions)
        
        XCTAssertNotNil(sharedWarehouser)
    }
    
    func testMultipleSharedEventWarehouserInstances() {
        let sharedDependencies = SharedEventSchedulerDependencies(
            socketNetworkBuilder: socketNetworkBuildable,
            courierNetworkBuilder: courierNetworkBuildable,
            db: database
        )
        
        let networkOptions1 = ClickstreamNetworkOptions(isWebsocketEnabled: true, isCourierEnabled: false)
        let networkOptions2 = ClickstreamNetworkOptions(isWebsocketEnabled: false, isCourierEnabled: true)

        let warehouser1 = sharedDependencies.makeSharedEventWarehouser(with: networkOptions1)
        let warehouser2 = sharedDependencies.makeSharedEventWarehouser(with: networkOptions2)
        
        XCTAssertNotNil(warehouser1)
        XCTAssertNotNil(warehouser2)
    }
    
    func testSharedEventWarehouseWithDifferentDatabases() {
        let memoryDatabase = try! DefaultDatabase(qos: .WAL)
        
        let sharedDependencies = SharedEventSchedulerDependencies(
            socketNetworkBuilder: socketNetworkBuildable,
            courierNetworkBuilder: courierNetworkBuildable,
            db: memoryDatabase
        )
        
        let networkOptions = ClickstreamNetworkOptions(isWebsocketEnabled: true, isCourierEnabled: true)
        let sharedWarehouser = sharedDependencies.makeSharedEventWarehouser(with: networkOptions)
        
        XCTAssertNotNil(sharedWarehouser)
    }
    
    func testSharedEventWarehouseWithUnreachableNetworks() {
        let unreachableSocketRetryMech = DefaultRetryMechanism(
            networkService: socketNetworkService,
            reachability: NetworkReachabilityMock(isReachable: false),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: socketPersistance,
            keepAliveService: keepAliveService
        )
        
        let unreachableCourierRetryMech = DefaultRetryMechanism(
            networkService: courierNetworkService,
            reachability: NetworkReachabilityMock(isReachable: false),
            deviceStatus: deviceStatus,
            appStateNotifier: AppStateNotifierMock(state: .didBecomeActive),
            performOnQueue: mockQueue,
            persistence: socketPersistance,
            keepAliveService: keepAliveService
        )
        
        let unreachableSocketBuildable = DefaultNetworkBuilder(
            networkConfigs: socketConfig,
            retryMech: unreachableSocketRetryMech,
            performOnQueue: mockQueue
        )
        
        let unreachableCourierBuildable = DefaultNetworkBuilder(
            networkConfigs: courierConfig,
            retryMech: unreachableCourierRetryMech,
            performOnQueue: mockQueue
        )
        
        let sharedDependencies = SharedEventSchedulerDependencies(
            socketNetworkBuilder: unreachableSocketBuildable,
            courierNetworkBuilder: unreachableCourierBuildable,
            db: database
        )
        
        let networkOptions = ClickstreamNetworkOptions(isWebsocketEnabled: true, isCourierEnabled: true)
        let sharedWarehouser = sharedDependencies.makeSharedEventWarehouser(with: networkOptions)
        
        XCTAssertNotNil(sharedWarehouser)
    }
    
    func testSharedEventWarehouseWithBackgroundAppState() {
        let backgroundAppStateNotifier = AppStateNotifierMock(state: .didEnterBackground)
        
        let backgroundSocketRetryMech = DefaultRetryMechanism(
            networkService: socketNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: backgroundAppStateNotifier,
            performOnQueue: mockQueue,
            persistence: socketPersistance,
            keepAliveService: keepAliveService
        )
        
        let backgroundCourierRetryMech = DefaultRetryMechanism(
            networkService: courierNetworkService,
            reachability: NetworkReachabilityMock(isReachable: true),
            deviceStatus: deviceStatus,
            appStateNotifier: backgroundAppStateNotifier,
            performOnQueue: mockQueue,
            persistence: socketPersistance,
            keepAliveService: keepAliveService
        )
        
        let backgroundSocketBuildable = DefaultNetworkBuilder(
            networkConfigs: socketConfig,
            retryMech: backgroundSocketRetryMech,
            performOnQueue: mockQueue
        )
        
        let backgroundCourierBuildable = DefaultNetworkBuilder(
            networkConfigs: courierConfig,
            retryMech: backgroundCourierRetryMech,
            performOnQueue: mockQueue
        )
        
        let sharedDependencies = SharedEventSchedulerDependencies(
            socketNetworkBuilder: backgroundSocketBuildable,
            courierNetworkBuilder: backgroundCourierBuildable,
            db: database
        )
        
        let networkOptions = ClickstreamNetworkOptions(isWebsocketEnabled: true, isCourierEnabled: true)
        let sharedWarehouser = sharedDependencies.makeSharedEventWarehouser(with: networkOptions)
        
        XCTAssertNotNil(sharedWarehouser)
    }
}
