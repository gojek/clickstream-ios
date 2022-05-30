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
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        
        let expectation = self.expectation(description: "Should not throw exception")

        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        SerialQueue.registerDetection(of: mockQueue) //Registers a queue to be detected.
        
        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: mockQueue)
        let keepAliveService = DefaultKeepAliveService(with: mockQueue, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: mockQueue, persistence: persistence, keepAliveService: keepAliveService)
        
        //when
        let sut = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: mockQueue)
        
        sut.trackBatch(self.eventBatchMock, completion: { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        })
        //then
        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_whenNetworkIsConnected_thenIsConnectedFlagMustBeSet() {
        //given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        let expectation = self.expectation(description: "Should return isAvailable flag as true")
        
        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        SerialQueue.registerDetection(of: mockQueue) //Registers a queue to be detected.
        
        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAliveService = DefaultKeepAliveService(with: mockQueue, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: mockQueue, persistence: persistence, keepAliveService: keepAliveService)
        
        //when
        let sut = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: mockQueue)
        SerialQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertEqual(sut.isAvailable, true)
            expectation.fulfill()
        }
        
        //then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_whenNetworkIsConnectedAndAppMovesToBackground_thenIsConnectedFlagMustNotBeSet() {
        
        //given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        let expectation = self.expectation(description: "Should return isAvailable flag as false")
        
        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        SerialQueue.registerDetection(of: mockQueue) //Registers a queue to be detected.
        
        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAliveService = DefaultKeepAliveService(with: mockQueue, duration: 10, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .willResignActive), performOnQueue: mockQueue, persistence: persistence, keepAliveService: keepAliveService)
        
        //when
        let sut = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: mockQueue)
        SerialQueue.main.asyncAfter(deadline: .now() + 3.0) {
            XCTAssertEqual(sut.isAvailable, false)
            expectation.fulfill()
        }
        
        //then
        wait(for: [expectation], timeout: 5.0)
    }

}

