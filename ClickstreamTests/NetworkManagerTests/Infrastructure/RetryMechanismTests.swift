//
//  RetryMechanismTests.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 29/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class RetryMechanismTests: XCTestCase {

    private let database = try! DefaultDatabase(qos: .utility)
    private let dbQueueMock = DispatchQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
    private var constraints: ClickstreamConstraints!
    private var prioritiesMock: [Priority]!

    override func setUp() {
        self.prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1),
        Priority(priority: 1, identifier: "standard")]
        self.constraints = ClickstreamConstraints(maxConnectionRetries: 15, maxConnectionRetryInterval: 5, maxRetryIntervalPostPrematureDisconnection: 10, maxRetriesPostPrematureDisconnection: 20, maxPingInterval: 15, priorities: prioritiesMock, flushOnBackground: true, connectionTerminationTimerWaitTime: 2, maxRequestAckTimeout: 0.5, maxRetriesPerBatch: 2, maxRetryCacheSize: 100000, connectionRetryDuration: 3, flushOnAppLaunch: false, minBatteryLevelPercent: 10.0)
        Clickstream.configurations = constraints
        Clickstream.eventClassifier = MockConstants.eventClassification
        Tracker.debugMode = true
    }
    
    func test_whenNetworkIsNotAvailable_thenRetryMechanismMustRetryFailedBatches() {
        //given
        let config = DefaultNetworkConfiguration(request: URLRequest(url: URL(string: "ws://mock.clickstream.com")!))
        let expectation = self.expectation(description: "The batch must be retried")
        
        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        SerialQueue.registerDetection(of: mockQueue)
        
        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let networkService = WebsocketNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAliveService = DefaultKeepAliveServiceWithSafeTimer(with: mockQueue, duration: 2, reachability: NetworkReachabilityMock(isReachable: false))

        //when
        let sut = WebsocketRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: mockQueue, persistence: persistence, keepAliveService: keepAliveService)
        
        persistence.deleteAll()

        let mockEventRequest: EventRequest = EventRequest(guid: UUID().uuidString, data: Data())
        
        sut.trackBatch(with: mockEventRequest)

        var checkCount = 0
        let maxChecks = 20
        let checkInterval: TimeInterval = 0.5
        
        func checkRetries() {
            mockQueue.asyncAfter(deadline: .now() + checkInterval) {
                checkCount += 1
                if (mockEventRequest.eventType != .instant), let fetchedRequest = persistence.fetchAll()?.first {
                    if fetchedRequest.retriesMade > 0 {
                        expectation.fulfill()
                        return
                    }
                }
                if checkCount < maxChecks {
                    checkRetries()
                }
            }
        }
        
        checkRetries()
        
        //then
        wait(for: [expectation], timeout: 15.0)
    }

    func test_whenTheMaxRetriesAreReached_thenTheBatchMustGetRemovedFromTheCache() {
        
        //given
        let config = DefaultNetworkConfiguration(request: URLRequest(url: URL(string: "ws://mock.clickstream.com")!))
        let expectation = self.expectation(description: "batch with exhausted retries must be removed")
        
        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
        SerialQueue.registerDetection(of: mockQueue) //Registers a queue to be detected.
        
        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let networkService = WebsocketNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAliveService = DefaultKeepAliveServiceWithSafeTimer(with: mockQueue, duration: 2, reachability: NetworkReachabilityMock(isReachable: false))

        //when
        let sut = WebsocketRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: mockQueue, persistence: persistence, keepAliveService: keepAliveService)
        
        persistence.deleteAll()

        let mockEventRequest: EventRequest = EventRequest(guid: UUID().uuidString, data: Data())
        
        sut.trackBatch(with: mockEventRequest)

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5) {
            if let count = persistence.fetchAll()?.count, count == 0 {
                expectation.fulfill()
            }
        }
        
        //then
        wait(for: [expectation], timeout: 6.0)
    }
}
