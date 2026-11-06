//
//  NetworkBuilderTests.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 05/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class NetworkBuilderTests: XCTestCase {
    
    private let database = try! DefaultDatabase(qos: .utility)
    private let dbQueueMock = DispatchQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
    
    private var eventBatchMock: EventBatch {
        let event = Event(guid: "", timestamp: Date(), type: "realTime", eventProtoData: Data())
        return EventBatch(uuid: UUID().uuidString, events: [event])
    }
    
    func test_whenSerialisableMockDataIsPassed_shouldNotThrowException() {
        //given
        let config = DefaultNetworkConfiguration(request: URLRequest(url: URL(string: "ws://mock.clickstream.com")!))
        
        let expectation = self.expectation(description: "Should not throw exception")

        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        SerialQueue.registerDetection(of: mockQueue) //Registers a queue to be detected.
        
        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let networkService = WebsocketNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: mockQueue)
        let keepAliveService = DefaultKeepAliveServiceWithSafeTimer(with: mockQueue, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let retryMech = WebsocketRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: mockQueue, persistence: persistence, keepAliveService: keepAliveService)
        
        //when
        let sut = WebsocketNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: mockQueue)
        
        sut.trackBatch(self.eventBatchMock, completion: { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        })
        //then
        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_whenNetworkIsConnected_thenIsConnectedFlagMustBeSet() {
        //given
        let config = DefaultNetworkConfiguration(request: URLRequest(url: URL(string: "ws://mock.clickstream.com")!))
        let expectation = self.expectation(description: "Should return isAvailable flag as true")
        
        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        SerialQueue.registerDetection(of: mockQueue) //Registers a queue to be detected.
        
        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let networkService = WebsocketNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAliveService = DefaultKeepAliveServiceWithSafeTimer(with: mockQueue, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = WebsocketRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: mockQueue, persistence: persistence, keepAliveService: keepAliveService)
        
        //when
        let sut = WebsocketNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: mockQueue)
        SerialQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertEqual(sut.isAvailable, true)
            expectation.fulfill()
        }
        
        //then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_whenNetworkIsConnectedAndAppMovesToBackground_thenIsConnectedFlagMustNotBeSet() {
        
        //given
        let config = DefaultNetworkConfiguration(request: URLRequest(url: URL(string: "ws://mock.clickstream.com")!))
        let expectation = self.expectation(description: "Should return isAvailable flag as false")

        // Pin the termination wait (2s) instead of inheriting whatever an earlier test left in the global config.
        let originalConfigurations = Clickstream.configurations
        Clickstream.configurations = MockConstants.constraints
        defer { Clickstream.configurations = originalConfigurations }

        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        SerialQueue.registerDetection(of: mockQueue) //Registers a queue to be detected.

        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let networkService = WebsocketNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        // AppStateNotifierMock fires synchronously during init, so keep-alive is restarted right after
        // willResignActive stops it. Use a long interval so it can't reconnect before the assertion runs.
        let keepAliveService = DefaultKeepAliveServiceWithSafeTimer(with: mockQueue, duration: 60, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = WebsocketRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .willResignActive), performOnQueue: mockQueue, persistence: persistence, keepAliveService: keepAliveService)
        
        //when
        let sut = WebsocketNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: mockQueue)
        // Termination fires after the 2s wait; check well after it, with a timeout that leaves headroom.
        SerialQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertEqual(sut.isAvailable, false)
            expectation.fulfill()
        }

        //then
        wait(for: [expectation], timeout: 15.0)
    }

}

