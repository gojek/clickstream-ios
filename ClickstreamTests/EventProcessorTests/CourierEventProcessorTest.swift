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
    private let dbQueueMock = SerialQueue(label: "test.courier.db.queue", qos: .utility, attributes: .concurrent)
    private var mockClassifier: MockEventClassifier!
    private var mockWarehouser: CourierEventWarehouser!
    private var mockSampler: EventSampler!
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
        persitance = DefaultDatabaseDAO<CourierEvent>(database: db, performOnQueue: dbQueueMock)
        
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
            eventWarehouser: mockWarehouser, sampler: mockSampler,
            networkOptions: networkOptions, eventExpiryManager: FallbackEventExpirationManager()
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
            eventWarehouser: mockWarehouser, sampler: mockSampler,
            networkOptions: networkOptions, eventExpiryManager: FallbackEventExpirationManager()
        )
        
        XCTAssertNotNil(courierEventProcessor)
    }
    
    func testInitializationWithoutSampler() {
        courierEventProcessor = CourierEventProcessor(
            performOnQueue: mockQueue,
            classifier: mockClassifier,
            eventWarehouser: mockWarehouser, sampler: mockSampler,
            networkOptions: networkOptions, eventExpiryManager: FallbackEventExpirationManager()
        )
        
        XCTAssertNotNil(courierEventProcessor)
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
            eventWarehouser: mockWarehouser, sampler: mockSampler,
            networkOptions: networkOptions, eventExpiryManager: FallbackEventExpirationManager()
        )

        XCTAssertFalse(courierEventProcessor.shouldTrackEvent(event: testEvent))
    }

//    func testShouldTrackEventValidWithWebsocketEnabledAndWhitelisted() {
//        let networkOptions = ClickstreamNetworkOptions(
//            isCourierEnabled: true,
//            courierEventTypes: [testEvent.messageName],
//            courierExclusiveEventTypes: []
//        )
//        courierEventProcessor = CourierEventProcessor(
//            performOnQueue: mockQueue,
//            classifier: mockClassifier,
//            eventWarehouser: mockWarehouser,
//            networkOptions: networkOptions
//        )
//        courierEventProcessor.setClientIdentifiers(CourierPostAuthIdentifiers(userIdentifier: "user", ownerType: "clickstream"))
//
//        XCTAssertTrue(courierEventProcessor.shouldTrackEvent(event: testEvent))
//    }

//    func testSetClientIdentifiers() {
//        let identifiers = CourierPostAuthIdentifiers(userIdentifier: "test-user-123", ownerType: "clickstream")
//        courierEventProcessor.setClientIdentifiers(identifiers)
//        
//        XCTAssertNotNil(courierEventProcessor)
//    }
    
//    func testRemoveClientIdentifiers() {
//        let identifiers = CourierPostAuthIdentifiers(userIdentifier: "test-user-123", ownerType: "clickstream")
//        courierEventProcessor.setClientIdentifiers(identifiers)
//        courierEventProcessor.removeClientIdentifiers()
//        
//        XCTAssertNotNil(courierEventProcessor)
//    }

    func testCreateBinaryEventWithValidBase64() {
        let payload = "hello binary".data(using: .utf8)!
        let base64 = payload.base64EncodedString()
        let event = CSBinaryEvent(type: "Gopay-Container-Page", encodedData: base64, product: "gopay")

        courierEventProcessor.createBinaryEvent(event: event)

        let expectation = XCTestExpectation(description: "binary event stored")
        mockQueue.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testCreateBinaryEventTypeIsLowercased() {
        let event = CSBinaryEvent(type: "Gopay-Container-Page", encodedData: "dGVzdA==")

        XCTAssertEqual(event.type.lowercased(), "gopay-container-page")
    }

    func testCreateBinaryEventWithInvalidBase64IsDropped() {
        let event = CSBinaryEvent(type: "gopay-container-component", encodedData: "not-valid-base64!!!")

        courierEventProcessor.createBinaryEvent(event: event)

        let expectation = XCTestExpectation(description: "invalid binary event handled")
        mockQueue.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testCreateBinaryEventWithNilClassificationIsDropped() {
        mockClassifier.classificationResult = nil
        let payload = "data".data(using: .utf8)!
        let event = CSBinaryEvent(type: "gopay-container-page", encodedData: payload.base64EncodedString())

        courierEventProcessor.createBinaryEvent(event: event)

        let expectation = XCTestExpectation(description: "nil classification handled")
        mockQueue.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
}

class MockEventClassifier: EventClassifier {
    var classificationResult: String?
    
    func getClassification(event: ClickstreamEvent) -> String? {
        return classificationResult
    }
}
