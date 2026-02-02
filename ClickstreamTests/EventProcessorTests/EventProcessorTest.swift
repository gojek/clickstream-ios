//
//  EventProcessorTest.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 24/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import SwiftProtobuf

class EventProcessorTest: XCTestCase {

    private let processorQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.processor", qos: .utility)
    private var config: DefaultNetworkConfiguration!
    private var networkService: WebsocketNetworkService<SocketHandlerMockSuccess>!
    private var retryMech: WebsocketRetryMechanism!
    private var networkBuilder: WebsocketNetworkBuilder!
    private var prioritiesMock: [Priority]!
    private var eventBatchCreator: DefaultEventBatchCreator!
    private var schedulerServiceMock: DefaultSchedulerService!
    private var appStateNotifierMock: AppStateNotifierMock!
    private var defaultEventBatchProcessor: DefaultEventBatchProcessor!
    private var eventWarehouser: DefaultEventWarehouser!
    private var persistence: DefaultDatabaseDAO<EventRequest>!
    private var eventPersistence: DefaultDatabaseDAO<Event>!
    private var keepAliveService: DefaultKeepAliveServiceWithSafeTimer!
    private let dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
    private let database = try! DefaultDatabase(qos: .WAL)
    private let batchSizeRegulator = DefaultBatchSizeRegulator()
    
    private var mockClassifier: MockEventClassifier!
    private var eventProcessor: DefaultEventProcessor!
    private var testEvent: ClickstreamEvent!
    private var networkOptions: ClickstreamNetworkOptions!
    
    override func setUp() {
        //given
        /// Network builder
        config = DefaultNetworkConfiguration(request: URLRequest(url: URL(string: "ws://mock.clickstream.com")!))
        networkService = WebsocketNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        eventPersistence = DefaultDatabaseDAO<Event>(database: database, performOnQueue: dbQueueMock)

        keepAliveService = DefaultKeepAliveServiceWithSafeTimer(with: processorQueueMock, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        retryMech = WebsocketRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: DefaultDeviceStatus(performOnQueue: processorQueueMock), appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: processorQueueMock, persistence: persistence, keepAliveService: keepAliveService)
        networkBuilder = WebsocketNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: processorQueueMock)
        
        /// Event Splitter
        prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1)]
        eventBatchCreator = DefaultEventBatchCreator(with: networkBuilder, performOnQueue: processorQueueMock)
        schedulerServiceMock = DefaultSchedulerService(with: prioritiesMock, performOnQueue: processorQueueMock)
        appStateNotifierMock = AppStateNotifierMock(state: .didBecomeActive)
        defaultEventBatchProcessor = DefaultEventBatchProcessor(with: eventBatchCreator, schedulerService: schedulerServiceMock, appStateNotifier: appStateNotifierMock, batchSizeRegulator: batchSizeRegulator, persistence: eventPersistence)
        eventWarehouser = DefaultEventWarehouser(with: defaultEventBatchProcessor, performOnQueue: processorQueueMock, persistence: eventPersistence, batchSizeRegulator: batchSizeRegulator)
        
        mockClassifier = MockEventClassifier()
        mockClassifier.classificationResult = "test-classification"
        
        networkOptions = ClickstreamNetworkOptions()
        
        eventProcessor = DefaultEventProcessor(
            performOnQueue: processorQueueMock,
            classifier: mockClassifier,
            eventWarehouser: eventWarehouser,
            networkOptions: networkOptions
        )
        
        testEvent = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: nil,
            eventName: "test.event.name",
            eventData: Data(),
            product: "CSTestProduct"
        )
    }

    override func tearDown() {
        config = nil
        networkService = nil
        retryMech = nil
        networkBuilder = nil
        prioritiesMock = nil
        eventBatchCreator = nil
        schedulerServiceMock = nil
        eventPersistence.deleteAll()
        appStateNotifierMock = nil
        defaultEventBatchProcessor = nil
        eventWarehouser = nil
        eventProcessor = nil
        mockClassifier = nil
        testEvent = nil
        networkOptions = nil
    }
    
    func testInitialization() {
        XCTAssertNotNil(eventProcessor)
    }
    
    func testInitializationWithSampler() {
        let sampler = MockEventSampler(shouldTrack: true)
        let processor = DefaultEventProcessor(
            performOnQueue: processorQueueMock,
            classifier: mockClassifier,
            eventWarehouser: eventWarehouser,
            sampler: sampler,
            networkOptions: networkOptions
        )
        
        XCTAssertNotNil(processor)
    }
    
    func testShouldTrackEventWithoutSampler() {
        XCTAssertTrue(eventProcessor.shouldTrackEvent(event: testEvent))
    }
    
    func testShouldTrackEventWithSamplerReturnsTrue() {
        let sampler = MockEventSampler(shouldTrack: true)
        let processor = DefaultEventProcessor(
            performOnQueue: processorQueueMock,
            classifier: mockClassifier,
            eventWarehouser: eventWarehouser,
            sampler: sampler,
            networkOptions: networkOptions
        )
        
        XCTAssertTrue(processor.shouldTrackEvent(event: testEvent))
    }
    
    func testShouldTrackEventWithSamplerReturnsFalse() {
        let sampler = MockEventSampler(shouldTrack: false)
        let processor = DefaultEventProcessor(
            performOnQueue: processorQueueMock,
            classifier: mockClassifier,
            eventWarehouser: eventWarehouser,
            sampler: sampler,
            networkOptions: networkOptions
        )
        
        XCTAssertFalse(processor.shouldTrackEvent(event: testEvent))
    }
    
    func testShouldTrackEventValidWithWebsocketDisabled() {
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            isCourierEnabled: false
        )
        let processor = DefaultEventProcessor(
            performOnQueue: processorQueueMock,
            classifier: mockClassifier,
            eventWarehouser: eventWarehouser,
            networkOptions: networkOptions
        )
        
        XCTAssertTrue(processor.shouldTrackEvent(event: testEvent))
    }
    
    func testShouldTrackEventValidWithCourierDisabled() {
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            isCourierEnabled: false
        )
        let processor = DefaultEventProcessor(
            performOnQueue: processorQueueMock,
            classifier: mockClassifier,
            eventWarehouser: eventWarehouser,
            networkOptions: networkOptions
        )
        
        XCTAssertTrue(processor.shouldTrackEvent(event: testEvent))
    }
}

class MockEventSampler: EventSampler {
    private let shouldTrackResult: Bool
    
    init(shouldTrack: Bool) {
        self.shouldTrackResult = shouldTrack
    }
    
    func shouldTrack(event: ClickstreamEvent) -> Bool {
        return shouldTrackResult
    }
}
