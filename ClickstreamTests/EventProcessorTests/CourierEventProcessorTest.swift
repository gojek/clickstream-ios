//
//  CourierEventProcessorTest.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 14/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import SwiftProtobuf

class CourierEventProcessorTest: XCTestCase {
    
    private var mockQueue: SerialQueue!
    private var mockClassifier: MockEventClassifier!
    private var mockWarehouser: CourierEventWarehouser!
    private var mockSampler: MockEventSampler!
    private var courierEventProcessor: CourierEventProcessor!
    private var courierBatchEventProcessor: CourierEventBatchProcessor!
    private var courierBatchCreator: CourierEventBatchCreator!
    private var courierNetworkBuilder: (any NetworkBuildable)!

    private var testEvent: ClickstreamEvent!
    private var networkOptions: ClickstreamNetworkOptions!
    private var batchSizeRegulator: CourierBatchSizeRegulator!
    private var persitance: DefaultDatabaseDAO<CourierEvent>!

    override func setUp() {
        let db = try! DefaultDatabase(qos: .WAL)

        mockQueue = SerialQueue(label: "test.queue", qos: .utility)
        mockClassifier = MockEventClassifier()
        mockSampler = MockEventSampler()

        networkOptions = ClickstreamNetworkOptions()
        batchSizeRegulator = CourierBatchSizeRegulator()
        persitance = DefaultDatabaseDAO<CourierEvent>(database: db, performOnQueue: mockQueue)
        
        courierNetworkBuilder = MockNetworkBuilder()
        courierBatchCreator = CourierEventBatchCreator(with: courierNetworkBuilder, performOnQueue: mockQueue)
        
        courierBatchEventProcessor = CourierEventBatchProcessor(with: courierBatchCreator,
                                                                schedulerService: MockSchedulerService(),
                                                                appStateNotifier: MockAppStateNotifierService(),
                                                                batchSizeRegulator: batchSizeRegulator,
                                                                persistence: persitance)
        mockWarehouser = CourierEventWarehouser(
            with: courierBatchEventProcessor,
            performOnQueue: mockQueue,
            persistance: persitance,
            batchSizeRegulator: batchSizeRegulator,
            networkOptions: networkOptions
        )
        
        mockClassifier.classificationResult = "test-classification"
        
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser
        )

        testEvent = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: nil,
            eventName: "test.event.name",
            eventData: Data()
        )

        super.setUp()
    }
    
    override func tearDown() {
        courierEventProcessor = nil
        mockQueue = nil
        mockClassifier = nil
        mockWarehouser = nil
        mockSampler = nil
        testEvent = nil
        super.tearDown()
    }
    
    func testInitialization() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            sampler: mockSampler
        )
        
        XCTAssertNotNil(courierEventProcessor)
    }
    
    func testInitializationWithoutSampler() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser
        )
        
        XCTAssertNotNil(courierEventProcessor)
    }
    
    func testShouldTrackEventWithSampler() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            sampler: mockSampler
        )
        
        mockSampler.shouldTrackResult = true
        XCTAssertTrue(courierEventProcessor.shouldTrackEvent(event: testEvent))
        
        mockSampler.shouldTrackResult = false
        XCTAssertFalse(courierEventProcessor.shouldTrackEvent(event: testEvent))
    }
    
    func testShouldTrackEventWithoutSampler() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser
        )
        
        XCTAssertTrue(courierEventProcessor.shouldTrackEvent(event: testEvent))
    }
}

class MockEventClassifier: EventClassifier {
    var classificationResult: String?
    
    func getClassification(event: ClickstreamEvent) -> String? {
        return classificationResult
    }
}

class MockEventSampler: EventSampler {
    var shouldTrackResult = true
    
    func shouldTrack(event: ClickstreamEvent) -> Bool {
        return shouldTrackResult
    }
}
