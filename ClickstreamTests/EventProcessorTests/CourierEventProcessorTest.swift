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

        networkOptions = ClickstreamNetworkOptions()
        mockQueue = SerialQueue(label: "test.queue", qos: .utility)
        mockClassifier = MockEventClassifier()

        networkOptions = ClickstreamNetworkOptions()
        batchSizeRegulator = CourierBatchSizeRegulator()
        persitance = DefaultDatabaseDAO<CourierEvent>(database: db, performOnQueue: mockQueue)
        
        courierNetworkBuilder = MockNetworkBuilder()
        courierBatchCreator = CourierEventBatchCreator(with: courierNetworkBuilder, performOnQueue: mockQueue, healthTrackingConfig: .init())
        
        courierBatchEventProcessor = CourierEventBatchProcessor(with: courierBatchCreator,
                                                                schedulerService: MockSchedulerService(),
                                                                appStateNotifier: MockAppStateNotifierService(),
                                                                batchSizeRegulator: batchSizeRegulator,
                                                                persistence: persitance)
        mockWarehouser = CourierEventWarehouser(
            with: courierBatchEventProcessor,
            performOnQueue: mockQueue,
            persistence: persitance,
            batchSizeRegulator: batchSizeRegulator,
            networkOptions: networkOptions
        )
        
        mockClassifier.classificationResult = "test-classification"
        
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
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

        super.setUp()
    }
    
    override func tearDown() {
        courierEventProcessor = nil
        mockQueue = nil
        mockClassifier = nil
        mockWarehouser = nil
        testEvent = nil
        super.tearDown()
    }
    
    func testInitialization() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            networkOptions: networkOptions
        )
        
        XCTAssertNotNil(courierEventProcessor)
    }
    
    func testInitializationWithoutSampler() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            networkOptions: networkOptions
        )
        
        XCTAssertNotNil(courierEventProcessor)
    }
    
    func testShouldTrackEventValidWithWebsocketDisabled() {
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            courierEventTypes: [],
            courierExclusiveEventTypes: []
        )
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            networkOptions: networkOptions
        )
        
        XCTAssertTrue(courierEventProcessor.shouldTrackEvent(event: testEvent))
    }
    
    func testShouldTrackEventInvalidWithWebsocketEnabledAndNotWhitelisted() {
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            courierEventTypes: [],
            courierExclusiveEventTypes: []
        )
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            networkOptions: networkOptions
        )

        XCTAssertFalse(courierEventProcessor.shouldTrackEvent(event: testEvent))
    }

    func testShouldTrackEventValidWithWebsocketEnabledAndWhitelisted() {
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            courierEventTypes: [testEvent.messageName],
            courierExclusiveEventTypes: []
        )
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            networkOptions: networkOptions
        )

        XCTAssertTrue(courierEventProcessor.shouldTrackEvent(event: testEvent))
    }

    func testShouldTrackEventValidWithCourierExclusiveEvent() {
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            courierEventTypes: [],
            courierExclusiveEventTypes: [testEvent.messageName]
        )
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser,
            networkOptions: networkOptions
        )

        XCTAssertTrue(courierEventProcessor.shouldTrackEvent(event: testEvent))
    }
    
    func testSetClientIdentifiers() {
        let identifiers = CourierIdentifiers(userIdentifier: "test-user-123")
        courierEventProcessor.setClientIdentifiers(identifiers)
        
        XCTAssertNotNil(courierEventProcessor)
    }
    
    func testRemoveClientIdentifiers() {
        let identifiers = CourierIdentifiers(userIdentifier: "test-user-123")
        courierEventProcessor.setClientIdentifiers(identifiers)
        courierEventProcessor.removeClientIdentifiers()
        
        XCTAssertNotNil(courierEventProcessor)
    }
}

class MockEventClassifier: EventClassifier {
    var classificationResult: String?
    
    func getClassification(event: ClickstreamEvent) -> String? {
        return classificationResult
    }
}
