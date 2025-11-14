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
    private var mockWarehouser: MockEventWarehouser!
    private var mockSampler: MockEventSampler!
    private var courierEventProcessor: CourierEventProcessor!
    private var testEvent: ClickstreamEvent!
    
    override func setUp() {
        super.setUp()
        mockQueue = SerialQueue(label: "test.queue", qos: .utility)
        mockClassifier = MockEventClassifier()
        mockWarehouser = MockEventWarehouser()
        mockSampler = MockEventSampler()
        
        testEvent = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: nil,
            eventName: "test.event.name",
            eventData: Data()
        )
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
    
    func testCreateEventSuccess() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            sampler: mockSampler
        )
        
        mockSampler.shouldTrackResult = true
        mockClassifier.classificationResult = "realtime"
        
        let expectation = XCTestExpectation(description: "Event stored")
        mockWarehouser.onStore = { _ in
            expectation.fulfill()
        }
        
        courierEventProcessor.createEvent(event: testEvent)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockWarehouser.storeCallCount, 1)
    }
    
    func testCreateEventWhenShouldNotTrack() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            sampler: mockSampler
        )
        
        mockSampler.shouldTrackResult = false
        
        let expectation = XCTestExpectation(description: "Event should not be stored")
        expectation.isInverted = true
        
        mockWarehouser.onStore = { _ in
            expectation.fulfill()
        }
        
        courierEventProcessor.createEvent(event: testEvent)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockWarehouser.storeCallCount, 0)
    }
    
    func testCreateEventWithInvalidEventName() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            sampler: mockSampler
        )
        
        let invalidEvent = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: nil,
            eventName: "",
            eventData: Data()
        )
        
        mockSampler.shouldTrackResult = true
        
        let expectation = XCTestExpectation(description: "Invalid event should not be stored")
        expectation.isInverted = true
        
        mockWarehouser.onStore = { _ in
            expectation.fulfill()
        }
        
        courierEventProcessor.createEvent(event: invalidEvent)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockWarehouser.storeCallCount, 0)
    }
    
    func testCreateEventWithNoClassification() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            sampler: mockSampler
        )
        
        mockSampler.shouldTrackResult = true
        mockClassifier.classificationResult = nil
        
        let expectation = XCTestExpectation(description: "Event with no classification should not be stored")
        expectation.isInverted = true
        
        mockWarehouser.onStore = { _ in
            expectation.fulfill()
        }
        
        courierEventProcessor.createEvent(event: testEvent)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockWarehouser.storeCallCount, 0)
    }
    
    func testCreateEventWithAppPrefix() {
        let originalPrefix = Clickstream.appPrefix
        Clickstream.appPrefix = "testapp"
        
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            sampler: mockSampler
        )
        
        mockSampler.shouldTrackResult = true
        mockClassifier.classificationResult = "realtime"
        
        let expectation = XCTestExpectation(description: "Event stored with prefix")
        mockWarehouser.onStore = { event in
            expectation.fulfill()
        }
        
        courierEventProcessor.createEvent(event: testEvent)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockWarehouser.storeCallCount, 1)
        
        Clickstream.appPrefix = originalPrefix
    }
}

class MockEventClassifier: EventClassifier {
    var classificationResult: String?
    
    func getClassification(event: ClickstreamEvent) -> String? {
        return classificationResult
    }
}

class MockEventWarehouser: EventWarehouser {
    var storeCallCount = 0
    var onStore: ((Event) -> Void)?
    
    func store(_ event: Event) {
        storeCallCount += 1
        onStore?(event)
    }
    
    var stopCallCount = 0
    var onStop: (() -> Void)?

    func stop() {
        stopCallCount += 1
        onStop?()
    }
}

class MockEventSampler: EventSampler {
    var shouldTrackResult = true
    
    func shouldTrack(event: ClickstreamEvent) -> Bool {
        return shouldTrackResult
    }
}
