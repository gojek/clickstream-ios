//
//  ClickstreamNetworkOptionsTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 07/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class ClickstreamNetworkOptionsTests: XCTestCase {
    
    func testDefaultInitializationWithAllProperties() {
        let options = ClickstreamNetworkOptions()
        
        XCTAssertTrue(options.isWebsocketEnabled)
        XCTAssertTrue(options.isCourierEnabled)
        XCTAssertTrue(options.courierEventTypes.isEmpty)
        XCTAssertNotNil(options.courierRetryPolicy)
        XCTAssertNotNil(options.courierRetryHTTPPolicy)
        XCTAssertNotNil(options.courierConfig)
        XCTAssertNotNil(options.clickstreamConstraints)
    }
    
    func testFullCustomInitialization() {
        let eventTypes: Set<CourierEventIdentifier> = ["event1", "event2", "event3"]
        let retryPolicy = ClickstreamCourierRetryPolicy()
        let httpRetryPolicy = ClickstreamCourierHTTPRetryPolicy()
        let courierConfig = ClickstreamCourierClientConfig()
        let constraints = ClickstreamCourierConstraints()
        
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            isCourierEnabled: true,
            courierEventTypes: eventTypes,
            courierRetryPolicy: retryPolicy,
            courierRetryHTTPPolicy: httpRetryPolicy,
            courierConfig: courierConfig,
            clickstreamConstraints: constraints
        )
        
        XCTAssertFalse(options.isWebsocketEnabled)
        XCTAssertTrue(options.isCourierEnabled)
        XCTAssertEqual(options.courierEventTypes, eventTypes)
        XCTAssertEqual(options.courierRetryPolicy.isEnabled, retryPolicy.isEnabled)
        XCTAssertEqual(options.courierRetryHTTPPolicy.isEnabled, httpRetryPolicy.isEnabled)
        XCTAssertEqual(options.courierConfig.courierPingIntervalMillis, courierConfig.courierPingIntervalMillis)
        XCTAssertEqual(options.clickstreamConstraints.maxRequestAckTimeout, constraints.maxRequestAckTimeout)
    }
    
    func testPartialCustomInitialization() {
        let eventTypes: Set<CourierEventIdentifier> = ["custom_event"]
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            courierEventTypes: eventTypes
        )
        
        XCTAssertFalse(options.isWebsocketEnabled)
        XCTAssertTrue(options.isCourierEnabled)
        XCTAssertEqual(options.courierEventTypes, eventTypes)
        XCTAssertNotNil(options.courierRetryPolicy)
        XCTAssertNotNil(options.courierRetryHTTPPolicy)
        XCTAssertNotNil(options.courierConfig)
        XCTAssertNotNil(options.clickstreamConstraints)
    }
    
    func testEmptyEventTypesSet() {
        let options = ClickstreamNetworkOptions(
            isCourierEnabled: true,
            courierEventTypes: Set<CourierEventIdentifier>()
        )
        
        XCTAssertTrue(options.isCourierEnabled)
        XCTAssertTrue(options.courierEventTypes.isEmpty)
        XCTAssertEqual(options.courierEventTypes.count, 0)
    }
    
    func testLargeEventTypesSet() {
        let eventTypes: Set<CourierEventIdentifier> = Set((1...100).map { "event_\($0)" })
        let options = ClickstreamNetworkOptions(courierEventTypes: eventTypes)
        
        XCTAssertEqual(options.courierEventTypes.count, 100)
        XCTAssertTrue(options.courierEventTypes.contains("event_1"))
        XCTAssertTrue(options.courierEventTypes.contains("event_100"))
    }
    
    func testCourierEventIdentifierTypeAlias() {
        let eventId: CourierEventIdentifier = "test_event"
        let eventTypes: Set<CourierEventIdentifier> = [eventId]
        let options = ClickstreamNetworkOptions(courierEventTypes: eventTypes)
        
        XCTAssertTrue(options.courierEventTypes.contains(eventId))
        XCTAssertTrue(eventId is String)
    }
}
