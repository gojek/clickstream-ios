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
    
    func testDefaultInitialization() {
        let options = ClickstreamNetworkOptions()
        
        XCTAssertTrue(options.isWebsocketEnabled)
        XCTAssertFalse(options.isCourierEnabled)
        XCTAssertTrue(options.courierEventTypes.isEmpty)
    }
    
    func testCustomInitialization() {
        let eventTypes: Set<CourierEventIdentifier> = ["event1", "event2"]
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            isCourierEnabled: true,
            courierEventTypes: eventTypes
        )
        
        XCTAssertFalse(options.isWebsocketEnabled)
        XCTAssertTrue(options.isCourierEnabled)
        XCTAssertEqual(options.courierEventTypes, eventTypes)
    }
    
    func testDecodingWithAllFields() throws {
        let json = """
        {
            "websocket_enabled": false,
            "courier_enabled": true,
            "event_types": ["event1", "event2", "event3"]
        }
        """
        
        let data = json.data(using: .utf8)!
        let options = try JSONDecoder().decode(ClickstreamNetworkOptions.self, from: data)
        
        XCTAssertFalse(options.isWebsocketEnabled)
        XCTAssertTrue(options.isCourierEnabled)
        XCTAssertEqual(options.courierEventTypes, Set(["event1", "event2", "event3"]))
    }
    
    func testDecodingWithMissingFields() throws {
        let json = "{}"
        
        let data = json.data(using: .utf8)!
        let options = try JSONDecoder().decode(ClickstreamNetworkOptions.self, from: data)
        
        XCTAssertTrue(options.isWebsocketEnabled)
        XCTAssertFalse(options.isCourierEnabled)
        XCTAssertTrue(options.courierEventTypes.isEmpty)
    }
    
    func testDecodingWithPartialFields() throws {
        let json = """
        {
            "websocket_enabled": false,
            "event_types": ["special_event"]
        }
        """
        
        let data = json.data(using: .utf8)!
        let options = try JSONDecoder().decode(ClickstreamNetworkOptions.self, from: data)
        
        XCTAssertFalse(options.isWebsocketEnabled)
        XCTAssertFalse(options.isCourierEnabled)
        XCTAssertEqual(options.courierEventTypes, Set(["special_event"]))
    }
    
    func testGetNetworkTypeForCourierEvent() {
        let eventTypes: Set<CourierEventIdentifier> = ["courier_event", "special_event"]
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            isCourierEnabled: true,
            courierEventTypes: eventTypes
        )
        
        XCTAssertEqual(options.getNetworkType(for: "courier_event"), .courier)
        XCTAssertEqual(options.getNetworkType(for: "special_event"), .courier)
    }
    
    func testGetNetworkTypeForWebsocketEvent() {
        let eventTypes: Set<CourierEventIdentifier> = ["courier_event"]
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            isCourierEnabled: true,
            courierEventTypes: eventTypes
        )
        
        XCTAssertEqual(options.getNetworkType(for: "regular_event"), .courier)
        XCTAssertEqual(options.getNetworkType(for: "unknown_event"), .courier)
    }
    
    func testGetNetworkTypeWhenCourierDisabled() {
        let eventTypes: Set<CourierEventIdentifier> = ["courier_event"]
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            isCourierEnabled: false,
            courierEventTypes: eventTypes
        )
        
        XCTAssertEqual(options.getNetworkType(for: "courier_event"), .websocket)
    }
    
    func testIsConfigEnabledWhenWebsocketEnabled() {
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            isCourierEnabled: false
        )
        
        XCTAssertTrue(options.isConfigEnabled())
    }
    
    func testIsConfigEnabledWhenCourierEnabled() {
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            isCourierEnabled: true
        )
        
        XCTAssertTrue(options.isConfigEnabled())
    }
    
    func testIsConfigEnabledWhenBothEnabled() {
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            isCourierEnabled: true
        )
        
        XCTAssertTrue(options.isConfigEnabled())
    }
    
    func testIsConfigDisabledWhenBothDisabled() {
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            isCourierEnabled: false
        )
        
        XCTAssertFalse(options.isConfigEnabled())
    }
    
    func testDecodingWithInvalidEventTypesFormat() throws {
        let json = """
        {
            "event_types": "invalid_format"
        }
        """
        
        let data = json.data(using: .utf8)!
        let options = try JSONDecoder().decode(ClickstreamNetworkOptions.self, from: data)
        
        XCTAssertTrue(options.courierEventTypes.isEmpty)
    }
}
