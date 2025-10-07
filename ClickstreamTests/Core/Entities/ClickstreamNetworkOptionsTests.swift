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
        XCTAssertEqual(options.courierHttpFallbackDelayMs, 500.0)
    }
    
    func testCustomInitialization() {
        let eventTypes: Set<CourierEventIdentifier> = ["event1", "event2"]
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            isCourierEnabled: true,
            courierEventTypes: eventTypes,
            httpFallbackDelayMs: 1000.0
        )
        
        XCTAssertFalse(options.isWebsocketEnabled)
        XCTAssertTrue(options.isCourierEnabled)
        XCTAssertEqual(options.courierEventTypes, eventTypes)
        XCTAssertEqual(options.courierHttpFallbackDelayMs, 1000.0)
    }
    
    func testDecodingWithAllFields() throws {
        let json = """
        {
            "websocket_enabled": false,
            "courier_enabled": true,
            "event_types": ["event1", "event2", "event3"],
            "http_fallback_delay": 750.5
        }
        """
        
        let data = json.data(using: .utf8)!
        let options = try JSONDecoder().decode(ClickstreamNetworkOptions.self, from: data)
        
        XCTAssertFalse(options.isWebsocketEnabled)
        XCTAssertTrue(options.isCourierEnabled)
        XCTAssertEqual(options.courierEventTypes, Set(["event1", "event2", "event3"]))
        XCTAssertEqual(options.courierHttpFallbackDelayMs, 750.5)
    }
    
    func testDecodingWithMissingFields() throws {
        let json = "{}"
        
        let data = json.data(using: .utf8)!
        let options = try JSONDecoder().decode(ClickstreamNetworkOptions.self, from: data)
        
        XCTAssertTrue(options.isWebsocketEnabled)
        XCTAssertFalse(options.isCourierEnabled)
        XCTAssertTrue(options.courierEventTypes.isEmpty)
        XCTAssertEqual(options.courierHttpFallbackDelayMs, 500.0)
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
        XCTAssertEqual(options.courierHttpFallbackDelayMs, 500.0)
    }
    
    func testDecodingHttpFallbackDelayAsInteger() throws {
        let json = """
        {
            "http_fallback_delay": 1000
        }
        """
        
        let data = json.data(using: .utf8)!
        let options = try JSONDecoder().decode(ClickstreamNetworkOptions.self, from: data)
        
        XCTAssertEqual(options.courierHttpFallbackDelayMs, 1000.0)
    }
    
    func testDecodingHttpFallbackDelayAsDouble() throws {
        let json = """
        {
            "http_fallback_delay": 1500.75
        }
        """
        
        let data = json.data(using: .utf8)!
        let options = try JSONDecoder().decode(ClickstreamNetworkOptions.self, from: data)
        
        XCTAssertEqual(options.courierHttpFallbackDelayMs, 1500.75)
    }
    
    func testEncoding() throws {
        let eventTypes: Set<CourierEventIdentifier> = ["event1", "event2"]
        let options = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            isCourierEnabled: true,
            courierEventTypes: eventTypes,
            httpFallbackDelayMs: 800.5
        )
        
        let data = try JSONEncoder().encode(options)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        XCTAssertEqual(json["websocket_enabled"] as? Bool, false)
        XCTAssertEqual(json["courier_enabled"] as? Bool, true)
        XCTAssertEqual(json["http_fallback_delay"] as? Double, 800.5)
        
        let encodedEventTypesArray = json["event_types"] as? [String]
        let encodedEventTypes = Set(encodedEventTypesArray ?? [])
        XCTAssertEqual(encodedEventTypes, eventTypes)
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
        
        XCTAssertEqual(options.getNetworkType(for: "regular_event"), .websocket)
        XCTAssertEqual(options.getNetworkType(for: "unknown_event"), .websocket)
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
    
    func testDecodingWithInvalidDelayFormat() throws {
        let json = """
        {
            "http_fallback_delay": "invalid_format"
        }
        """
        
        let data = json.data(using: .utf8)!
        let options = try JSONDecoder().decode(ClickstreamNetworkOptions.self, from: data)
        
        XCTAssertEqual(options.courierHttpFallbackDelayMs, 500.0)
    }
    
    func testRoundTripEncodingDecoding() throws {
        let originalOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            isCourierEnabled: true,
            courierEventTypes: ["event1", "event2", "event3"],
            httpFallbackDelayMs: 1250.75
        )
        
        let encodedData = try JSONEncoder().encode(originalOptions)
        let decodedOptions = try JSONDecoder().decode(ClickstreamNetworkOptions.self, from: encodedData)
        
        XCTAssertEqual(originalOptions.isWebsocketEnabled, decodedOptions.isWebsocketEnabled)
        XCTAssertEqual(originalOptions.isCourierEnabled, decodedOptions.isCourierEnabled)
        XCTAssertEqual(originalOptions.courierEventTypes, decodedOptions.courierEventTypes)
        XCTAssertEqual(originalOptions.courierHttpFallbackDelayMs, decodedOptions.courierHttpFallbackDelayMs)
    }
}
