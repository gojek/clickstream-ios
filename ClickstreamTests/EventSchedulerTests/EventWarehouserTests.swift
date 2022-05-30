//
//  EventWarehouserTests.swift.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 08/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class EventWarehouserTests: XCTestCase {

    private let database = try! DefaultDatabase(qos: .WAL)
    private let dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)

    private let schedulerQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.schedule", qos: .utility)
    private let realTimeEvent = Event(guid: "realTimeEvent", timestamp: Date(), type: "realTime", eventProtoData: Data())
    private let standardEvent = Event(guid: "standardEvent", timestamp: Date(), type: "standard", eventProtoData: Data())

    override func setUp() {
        
        Clickstream.constraints = MockConstants.constraints
        Clickstream.debugMode = true
    }
    
    func test_whenAnEventIsGiven_thenTheWarehouserMustStoreIt() {
        //given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        let expectation = self.expectation(description: "Should respond on the given queue")

        
        let prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 100),
                              Priority(priority: 1, identifier: "standard")]

        let persistence = DefaultDatabaseDAO<Event>(database: database, performOnQueue: dbQueueMock)
        
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        let keepAliveService = DefaultKeepAliveService(with: schedulerQueueMock, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: DefaultDeviceStatus(performOnQueue: schedulerQueueMock), appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: schedulerQueueMock, persistence: DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock), keepAliveService: keepAliveService)
        
        let networkBuilder = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: schedulerQueueMock)
        let eventBatchCreator = DefaultEventBatchCreator(with: networkBuilder, performOnQueue: schedulerQueueMock)
        let schedulerServiceMock = DefaultSchedulerService(with: prioritiesMock, performOnQueue: schedulerQueueMock)
        let batchSizeRegulatorMock = DefaultBatchSizeRegulator()
        
        let appStateNotifierMock = AppStateNotifierMock(state: .didBecomeActive)
    
        let eventBatchProcessor = DefaultEventBatchProcessor(with: eventBatchCreator, schedulerService: schedulerServiceMock, appStateNotifier: appStateNotifierMock, batchSizeRegulator: batchSizeRegulatorMock, persistence: persistence)
        
        //when
        let sut = DefaultEventWarehouser(with: eventBatchProcessor, performOnQueue: schedulerQueueMock, persistence: persistence, batchSizeRegulator: batchSizeRegulatorMock)
        
        // clear previous data
        persistence.deleteAll()
        
        //then
        sut.store(realTimeEvent)
        sut.store(standardEvent)
        
        schedulerQueueMock.asyncAfter(deadline: .now() + 2.0) {
            if let events = persistence.deleteAll() {
                XCTAssertEqual(events.count, 2)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 4.0)
    }
}
