//
//  EventBatchProcessorTests.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 04/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class EventBatchProcessorTests: XCTestCase {

    private let database = try! DefaultDatabase(qos: .WAL)
    private let dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
    private let schedulerQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.schedule", qos: .utility)
    private var realTimeEvent: Event!
    private var standardEvent: Event!
    
    override func setUp() {
        realTimeEvent = Event(guid: "realTime", timestamp: Date(), type: "realTime", eventProtoData: Data())
        standardEvent = Event(guid: "standard", timestamp: Date(), type: "standard", eventProtoData: Data())
        
        Clickstream.constraints = MockConstants.constraints
        Clickstream.debugMode = true
    }
    
    func test_whenBatchSizeIsGiven_shouldForwardABatch() {
        //given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        let expectation = self.expectation(description: "Should respond on the given queue")
        
        let prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1)]

        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let eventPersistence = DefaultDatabaseDAO<Event>(database: database, performOnQueue: dbQueueMock)
        
        let keepAliveService = DefaultKeepAliveService(with: schedulerQueueMock, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))
      
        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: DefaultDeviceStatus(performOnQueue: schedulerQueueMock), appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: schedulerQueueMock, persistence: persistence, keepAliveService: keepAliveService)
        let networkBuilder = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: schedulerQueueMock)
        let eventBatchCreator = DefaultEventBatchCreator(with: networkBuilder, performOnQueue: schedulerQueueMock)
        let schedulerServiceMock = DefaultSchedulerService(with: prioritiesMock, performOnQueue: schedulerQueueMock)
        
        // clear previous data
        eventPersistence.deleteAll()
        persistence.deleteAll()
        
        eventPersistence.insert(realTimeEvent)
        
        let appStateNotifierMock = AppStateNotifierMock(state: .didBecomeActive)
        let batchRegulatorMock = BatchSizeRegulatorMock()
        
        //when
        let sut = DefaultEventBatchProcessor(with: eventBatchCreator, schedulerService: schedulerServiceMock, appStateNotifier: appStateNotifierMock, batchSizeRegulator: batchRegulatorMock, persistence: eventPersistence)
        
        
        //then
        sut.start()
        
        schedulerQueueMock.asyncAfter(deadline: .now() + 2.0) {
            if let events = eventPersistence.fetchFirst(50) {
                XCTAssertEqual(events.count, 0)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }
    
    func test_whenAppStateIsEnterBackground_thenAllEventsMustBeFlushed() {
        //given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        let expectation = self.expectation(description: "All events must get flushed")
        
        let prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 5000.0, maxTimeBetweenTwoBatches: 10),
                              Priority(priority: 1, identifier: "standard", maxBatchSize: 5000.0)]
        
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let eventPersistence = DefaultDatabaseDAO<Event>(database: database, performOnQueue: dbQueueMock)
        
        let keepAliveService = DefaultKeepAliveService(with: schedulerQueueMock, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: DefaultDeviceStatus(performOnQueue: schedulerQueueMock), appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: schedulerQueueMock, persistence: persistence, keepAliveService: keepAliveService)
        let networkBuilder = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: schedulerQueueMock)
        let eventBatchCreator = DefaultEventBatchCreator(with: networkBuilder, performOnQueue: schedulerQueueMock)
        let schedulerServiceMock = DefaultSchedulerService(with: prioritiesMock, performOnQueue: schedulerQueueMock)
        
        //ensuring old data is wiped before adding more
        eventPersistence.deleteAll()
        persistence.deleteAll()

        eventPersistence.insert(realTimeEvent)
        eventPersistence.insert(standardEvent)

        let appStateNotifierMock = AppStateNotifierMock(state: .didEnterBackground)
    
        //when
        let sut = DefaultEventBatchProcessor(with: eventBatchCreator, schedulerService: schedulerServiceMock, appStateNotifier: appStateNotifierMock, batchSizeRegulator: DefaultBatchSizeRegulator(), persistence: eventPersistence)

        //then
        sut.start()
        
        schedulerQueueMock.asyncAfter(deadline: .now() + 1.0) {
            if let events = eventPersistence.fetchAll() {
                XCTAssertEqual(events.count, 0)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }
}
