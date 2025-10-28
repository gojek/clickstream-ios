//
//  ClickstreamCourierConfigTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 15/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import CourierMQTT

class ClickstreamCourierConfigTests: XCTestCase {
    
    func testInitWithAllParameters() {
        let connectConfig = ClickstreamCourierConnectConfig(
            baseURL: "https://api.example.com",
            authURLPath: "/auth",
            tokenExpiryMins: 60.0,
            pingIntervalMs: 300.0,
            isCleanSessionEnabled: true,
            isTokenCacheExpiryEnabled: true,
            alpn: ["h2", "http/1.1"]
        )
        
        let config = ClickstreamCourierConfig(
            topics: ["topic1": 1, "topic2": 2],
            messageAdapter: [JSONMessageAdapter(), DataMessageAdapter()],
            isMessagePersistenceEnabled: true,
            autoReconnectInterval: 2.0,
            maxAutoReconnectInterval: 60.0,
            authenticationTimeoutInterval: 45.0,
            enableAuthenticationTimeout: true,
            connectConfig: connectConfig,
            messagePersistenceTTLSeconds: 86400,
            messageCleanupInterval: 20.0,
            shouldInitializeCoreDataPersistenceContext: false
        )
        
        XCTAssertEqual(config.topics.count, 2)
        XCTAssertEqual(config.messageAdapters.count, 2)
        XCTAssertTrue(config.isMessagePersistenceEnabled)
        XCTAssertEqual(config.autoReconnectInterval, 2.0)
        XCTAssertEqual(config.maxAutoReconnectInterval, 60.0)
        XCTAssertEqual(config.authenticationTimeoutInterval, 45.0)
        XCTAssertTrue(config.enableAuthenticationTimeout)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 86400)
        XCTAssertEqual(config.messageCleanupInterval, 20.0)
        XCTAssertFalse(config.shouldInitializeCoreDataPersistenceContext)
    }
    
    func testInitWithDefaultParameters() {
        let config = ClickstreamCourierConfig()
        
        XCTAssertTrue(config.topics.isEmpty)
        XCTAssertTrue(config.messageAdapters.isEmpty)
        XCTAssertFalse(config.isMessagePersistenceEnabled)
        XCTAssertEqual(config.autoReconnectInterval, 1.0)
        XCTAssertEqual(config.maxAutoReconnectInterval, 30.0)
        XCTAssertEqual(config.authenticationTimeoutInterval, 30.0)
        XCTAssertTrue(config.enableAuthenticationTimeout)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 0)
        XCTAssertEqual(config.messageCleanupInterval, 10.0)
        XCTAssertFalse(config.shouldInitializeCoreDataPersistenceContext)
    }
    
    func testDecodingWithValidJSON() throws {
        let json = """
        {
            "topics": {"topic1": 1, "topic2": 2},
            "message_adapters": ["json", "data"],
            "auto_reconnect_interval": 2.5,
            "max_auto_reconnect_interval": 45.0,
            "enable_authentication_timeout": true,
            "authentication_timeout_interval": 35.0,
            "message_persistence_ttl_seconds": 7200,
            "message_cleanup_interval": 15.0,
            "is_message_persistence_enabled": true,
            "should_initialize_core_data_persistence_context": false
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertEqual(config.topics["topic1"], 1)
        XCTAssertEqual(config.topics["topic2"], 2)
        XCTAssertEqual(config.messageAdapters.count, 2)
        XCTAssertEqual(config.autoReconnectInterval, 2.5)
        XCTAssertEqual(config.maxAutoReconnectInterval, 45.0)
        XCTAssertTrue(config.enableAuthenticationTimeout)
        XCTAssertEqual(config.authenticationTimeoutInterval, 35.0)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 7200)
        XCTAssertEqual(config.messageCleanupInterval, 15.0)
        XCTAssertTrue(config.isMessagePersistenceEnabled)
        XCTAssertFalse(config.shouldInitializeCoreDataPersistenceContext)
    }
    
    func testDecodingWithMissingFields() throws {
        let json = """
        {}
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertTrue(config.topics.isEmpty)
        XCTAssertTrue(config.messageAdapters.isEmpty)
        XCTAssertFalse(config.isMessagePersistenceEnabled)
        XCTAssertEqual(config.autoReconnectInterval, 1.0)
        XCTAssertEqual(config.maxAutoReconnectInterval, 30.0)
        XCTAssertFalse(config.enableAuthenticationTimeout)
        XCTAssertEqual(config.authenticationTimeoutInterval, 30.0)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 86400.0)
        XCTAssertEqual(config.messageCleanupInterval, 10.0)
        XCTAssertFalse(config.shouldInitializeCoreDataPersistenceContext)
    }
    
    func testDecodingWithPartialData() throws {
        let json = """
        {
            "topics": {"main": 0},
            "auto_reconnect_interval": "5.5",
            "enable_authentication_timeout": true
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertEqual(config.topics["main"], 0)
        XCTAssertEqual(config.autoReconnectInterval, 5.5)
        XCTAssertTrue(config.enableAuthenticationTimeout)
        XCTAssertEqual(config.maxAutoReconnectInterval, 30.0)
        XCTAssertTrue(config.messageAdapters.isEmpty)
    }
    
    func testDecodingWithInvalidAdapters() throws {
        let json = """
        {
            "message_adapters": ["json", "invalid_adapter"]
        }
        """.data(using: .utf8)!
        
        do {
            let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
            XCTAssertEqual(config.messageAdapters.count, 1)
        } catch {
            XCTFail("Decoding should handle invalid adapters gracefully")
        }
    }
    
    func testConnectConfigDefaults() throws {
        let json = """
        {}
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertEqual(config.connectConfig.baseURL, "")
        XCTAssertEqual(config.connectConfig.authURLPath, "")
        XCTAssertEqual(config.connectConfig.tokenExpiryMins, 36.0)
        XCTAssertEqual(config.connectConfig.pingIntervalMs, 10.0)
        XCTAssertFalse(config.connectConfig.isCleanSessionEnabled)
        XCTAssertFalse(config.connectConfig.isTokenCacheExpiryEnabled)
        XCTAssertFalse(config.connectConfig.alpn.isEmpty)
    }
    
    func testPolicyDefaults() throws {
        let json = """
        {}
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertNotNil(config.connectTimeoutPolicy)
        XCTAssertNotNil(config.iddleActivityPolicy)
    }
    
    func testTimeIntervalBoundaries() {
        let config = ClickstreamCourierConfig(
            autoReconnectInterval: 0.1,
            maxAutoReconnectInterval: 3600.0,
            authenticationTimeoutInterval: 120.0,
            messagePersistenceTTLSeconds: 604800,
            messageCleanupInterval: 1.0
        )
        
        XCTAssertEqual(config.autoReconnectInterval, 0.1)
        XCTAssertEqual(config.maxAutoReconnectInterval, 3600.0)
        XCTAssertEqual(config.authenticationTimeoutInterval, 120.0)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 604800)
        XCTAssertEqual(config.messageCleanupInterval, 1.0)
    }
}
