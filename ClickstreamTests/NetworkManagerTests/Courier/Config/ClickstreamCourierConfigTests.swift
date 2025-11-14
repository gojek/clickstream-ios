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
            enableAuthenticationTimeout: true,
            authenticationTimeoutInterval: 45.0,
            autoReconnectInterval: 2.0,
            maxAutoReconnectInterval: 60.0,
            tokenExpiryMins: 480.0,
            isTokenCacheExpiryEnabled: true,
            isConnectUserPropertiesEnabled: false,
            alpn: ["h2", "http/1.1"]
        )
        
        let config = ClickstreamCourierConfig(
            messageAdapter: [],
            connectConfig: connectConfig,
            connectTimeoutPolicy: ConnectTimeoutPolicy(),
            iddleActivityPolicy: IdleActivityTimeoutPolicy(),
            pingIntervalMs: 300.0,
            isCleanSessionEnabled: true,
            messagePersistenceTTLSeconds: 86400,
            messageCleanupInterval: 20.0,
            shouldInitializeCoreDataPersistenceContext: false,
            isMessagePersistenceEnabled: true
        )
        
        XCTAssertEqual(config.messageAdapters.count, 0)
        XCTAssertTrue(config.isMessagePersistenceEnabled)
        XCTAssertEqual(config.connectConfig.autoReconnectInterval, 2.0)
        XCTAssertEqual(config.connectConfig.maxAutoReconnectInterval, 60.0)
        XCTAssertEqual(config.connectConfig.authenticationTimeoutInterval, 45.0)
        XCTAssertTrue(config.connectConfig.enableAuthenticationTimeout)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 86400)
        XCTAssertEqual(config.messageCleanupInterval, 20.0)
        XCTAssertFalse(config.shouldInitializeCoreDataPersistenceContext)
        XCTAssertEqual(config.pingIntervalMs, 300.0)
        XCTAssertTrue(config.isCleanSessionEnabled)
    }
    
    func testInitWithDefaultParameters() {
        let config = ClickstreamCourierConfig()
        
        XCTAssertTrue(config.messageAdapters.isEmpty)
        XCTAssertFalse(config.isMessagePersistenceEnabled)
        XCTAssertEqual(config.connectConfig.autoReconnectInterval, 5.0)
        XCTAssertEqual(config.connectConfig.maxAutoReconnectInterval, 10.0)
        XCTAssertEqual(config.connectConfig.authenticationTimeoutInterval, 20.0)
        XCTAssertTrue(config.connectConfig.enableAuthenticationTimeout)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 86400.0)
        XCTAssertEqual(config.messageCleanupInterval, 10.0)
        XCTAssertFalse(config.shouldInitializeCoreDataPersistenceContext)
    }
    
    func testDecodingWithValidJSON() throws {
        let json = """
        {
            "message_adapters": ["json", "data"],
            "connect_config": {
                "auto_reconnect_interval": 2.5,
                "max_auto_reconnect_interval": 45.0,
                "enable_authentication_timeout": true,
                "authentication_timeout_interval": 35.0
            },
            "message_persistence_ttl_seconds": 7200,
            "message_cleanup_interval": 15.0,
            "is_message_persistence_enabled": true,
            "should_initialize_core_data_persistence_context": false
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)

        XCTAssertEqual(config.messageAdapters.count, 2)
        XCTAssertEqual(config.connectConfig.autoReconnectInterval, 2.5)
        XCTAssertEqual(config.connectConfig.maxAutoReconnectInterval, 45.0)
        XCTAssertTrue(config.connectConfig.enableAuthenticationTimeout)
        XCTAssertEqual(config.connectConfig.authenticationTimeoutInterval, 35.0)
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
        
        XCTAssertTrue(config.messageAdapters.isEmpty)
        XCTAssertFalse(config.isMessagePersistenceEnabled)
        XCTAssertEqual(config.connectConfig.autoReconnectInterval, 5.0)
        XCTAssertEqual(config.connectConfig.maxAutoReconnectInterval, 10.0)
        XCTAssertEqual(config.connectConfig.authenticationTimeoutInterval, 20.0)
        XCTAssertTrue(config.connectConfig.enableAuthenticationTimeout)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 86400.0)
        XCTAssertEqual(config.messageCleanupInterval, 10.0)
        XCTAssertFalse(config.shouldInitializeCoreDataPersistenceContext)
    }
    
    func testDecodingWithPartialData() throws {
        let json = """
        {
            "connect_config": {
                "auto_reconnect_interval": "5.5",
                "enable_authentication_timeout": true
            }
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertEqual(config.connectConfig.autoReconnectInterval, 5.5)
        XCTAssertTrue(config.connectConfig.enableAuthenticationTimeout)
        XCTAssertEqual(config.connectConfig.maxAutoReconnectInterval, 30.0)
        XCTAssertTrue(config.messageAdapters.isEmpty)
    }
    
    func testDecodingWithInvalidAdapters() throws {
        let json = """
        {
            "message_adapters": ["json", "invalid_adapter"]
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        XCTAssertEqual(config.messageAdapters.count, 1)
    }
    
    func testTimeIntervalBoundaries() {
        let connectConfig = ClickstreamCourierConnectConfig(
            authenticationTimeoutInterval: 120.0,
            autoReconnectInterval: 0.1,
            maxAutoReconnectInterval: 3600.0
        )
        
        let config = ClickstreamCourierConfig(
            connectConfig: connectConfig,
            messagePersistenceTTLSeconds: 604800,
            messageCleanupInterval: 1.0
        )
        
        XCTAssertEqual(config.connectConfig.autoReconnectInterval, 0.1)
        XCTAssertEqual(config.connectConfig.maxAutoReconnectInterval, 3600.0)
        XCTAssertEqual(config.connectConfig.authenticationTimeoutInterval, 120.0)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 604800)
        XCTAssertEqual(config.messageCleanupInterval, 1.0)
    }
    
    func testDecodingWithCompleteJSON() throws {
        let json = """
        {
            "message_adapters": ["json", "data"],
            "connect_config": {
                "enable_authentication_timeout": true,
                "authentication_timeout_interval": 45.0,
                "auto_reconnect_interval": 3.0,
                "max_auto_reconnect_interval": 120.0,
                "token_expiry_mins": 480.0,
                "token_expiry_cache_enabled": true,
                "is_connect_user_properties_enabled": false,
                "alpn": ["h2", "mqtt"]
            },
            "ping_interval_ms": 180.0,
            "clean_session_enabled": true,
            "message_persistence_ttl_seconds": 3600,
            "message_cleanup_interval": 30.0,
            "is_message_persistence_enabled": true,
            "should_initialize_core_data_persistence_context": true
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertEqual(config.messageAdapters.count, 2)
        XCTAssertTrue(config.connectConfig.enableAuthenticationTimeout)
        XCTAssertEqual(config.connectConfig.authenticationTimeoutInterval, 45.0)
        XCTAssertEqual(config.connectConfig.autoReconnectInterval, 3.0)
        XCTAssertEqual(config.connectConfig.maxAutoReconnectInterval, 120.0)
        XCTAssertEqual(config.connectConfig.tokenExpiryMins, 480.0)
        XCTAssertTrue(config.connectConfig.isTokenCacheExpiryEnabled)
        XCTAssertFalse(config.connectConfig.isConnectUserPropertiesEnabled)
        XCTAssertEqual(config.connectConfig.alpn, ["h2", "mqtt"])
        XCTAssertEqual(config.pingIntervalMs, 180.0)
        XCTAssertTrue(config.isCleanSessionEnabled)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 3600)
        XCTAssertEqual(config.messageCleanupInterval, 30.0)
        XCTAssertTrue(config.isMessagePersistenceEnabled)
        XCTAssertTrue(config.shouldInitializeCoreDataPersistenceContext)
    }
    
    func testDecodingWithEmptyMessageAdapters() throws {
        let json = """
        {
            "message_adapters": []
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        XCTAssertTrue(config.messageAdapters.isEmpty)
    }
    
    func testDecodingWithStringTimeIntervals() throws {
        let json = """
        {
            "ping_interval_ms": "300.5",
            "message_persistence_ttl_seconds": "7200",
            "message_cleanup_interval": "25.0"
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertEqual(config.pingIntervalMs, 300.5)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 7200)
        XCTAssertEqual(config.messageCleanupInterval, 25.0)
    }
    
    func testDecodingWithNullValues() throws {
        let json = """
        {
            "message_adapters": null,
            "connect_config": null,
            "ping_interval_ms": null,
            "clean_session_enabled": null,
            "is_message_persistence_enabled": null
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertTrue(config.messageAdapters.isEmpty)
        XCTAssertEqual(config.pingIntervalMs, 10.0)
        XCTAssertFalse(config.isCleanSessionEnabled)
        XCTAssertFalse(config.isMessagePersistenceEnabled)
    }
    
    func testInitParameterValidation() {
        let config = ClickstreamCourierConfig(
            messageAdapter: [],
            connectConfig: ClickstreamCourierConnectConfig(),
            connectTimeoutPolicy: ConnectTimeoutPolicy(),
            iddleActivityPolicy: IdleActivityTimeoutPolicy(),
            pingIntervalMs: 0.0,
            isCleanSessionEnabled: false,
            messagePersistenceTTLSeconds: -1,
            messageCleanupInterval: 0.5,
            shouldInitializeCoreDataPersistenceContext: true,
            isMessagePersistenceEnabled: true
        )
        
        XCTAssertEqual(config.pingIntervalMs, 0.0)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, -1)
        XCTAssertEqual(config.messageCleanupInterval, 0.5)
        XCTAssertTrue(config.shouldInitializeCoreDataPersistenceContext)
        XCTAssertTrue(config.isMessagePersistenceEnabled)
    }
    
    func testDecodingWithMixedAdapterTypes() throws {
        let json = """
        {
            "message_adapters": ["json", "unknown", "data", "", "json"]
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        XCTAssertEqual(config.messageAdapters.count, 3)
    }
    
    func testConfigEquality() {
        let config1 = ClickstreamCourierConfig(
            pingIntervalMs: 300.0,
            isCleanSessionEnabled: true,
            messagePersistenceTTLSeconds: 3600,
            messageCleanupInterval: 15.0,
            isMessagePersistenceEnabled: true
        )
        
        let config2 = ClickstreamCourierConfig(
            pingIntervalMs: 300.0,
            isCleanSessionEnabled: true,
            messagePersistenceTTLSeconds: 3600,
            messageCleanupInterval: 15.0,
            isMessagePersistenceEnabled: true
        )
        
        XCTAssertEqual(config1.pingIntervalMs, config2.pingIntervalMs)
        XCTAssertEqual(config1.isCleanSessionEnabled, config2.isCleanSessionEnabled)
        XCTAssertEqual(config1.messagePersistenceTTLSeconds, config2.messagePersistenceTTLSeconds)
        XCTAssertEqual(config1.messageCleanupInterval, config2.messageCleanupInterval)
        XCTAssertEqual(config1.isMessagePersistenceEnabled, config2.isMessagePersistenceEnabled)
    }
    
    func testDecodingWithInvalidBooleanValues() throws {
        let json = """
        {
            "clean_session_enabled": "true",
            "is_message_persistence_enabled": "false",
            "should_initialize_core_data_persistence_context": 1
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertFalse(config.isCleanSessionEnabled)
        XCTAssertFalse(config.isMessagePersistenceEnabled)
        XCTAssertFalse(config.shouldInitializeCoreDataPersistenceContext)
    }
    
    func testPolicyDefaults() throws {
        let json = """
        {}
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertNotNil(config.connectTimeoutPolicy)
        XCTAssertNotNil(config.iddleActivityPolicy)
    }
    
    func testRetryPolicyDefaults() {
        let config = ClickstreamCourierConfig()
        
        XCTAssertTrue(config.retryPolicy.isEnabled)
        XCTAssertEqual(config.retryPolicy.delayMillis, 500.0)
        XCTAssertEqual(config.retryPolicy.maxRetryCount, 3)
        XCTAssertTrue(config.httpRetryPolicy.isEnabled)
        XCTAssertEqual(config.httpRetryPolicy.delayMillis, 500.0)
        XCTAssertEqual(config.httpRetryPolicy.maxRetryCount, 3)
    }
    
    func testDecodingWithInvalidJSON() throws {
        let json = """
        {
            "message_adapters": "invalid",
            "ping_interval_ms": "not_a_number",
            "message_persistence_ttl_seconds": [],
            "message_cleanup_interval": {}
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertTrue(config.messageAdapters.isEmpty)
        XCTAssertEqual(config.pingIntervalMs, 10.0)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 86400.0)
        XCTAssertEqual(config.messageCleanupInterval, 10.0)
    }
    
    func testDecodingWithNegativeTimeValues() throws {
        let json = """
        {
            "ping_interval_ms": -100,
            "message_persistence_ttl_seconds": -500,
            "message_cleanup_interval": -10
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertEqual(config.pingIntervalMs, -100)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, -500)
        XCTAssertEqual(config.messageCleanupInterval, -10)
    }
    
    func testDecodingWithLargeTimeValues() throws {
        let json = """
        {
            "ping_interval_ms": 999999.99,
            "message_persistence_ttl_seconds": 31536000,
            "message_cleanup_interval": 3600.5
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertEqual(config.pingIntervalMs, 999999.99)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 31536000)
        XCTAssertEqual(config.messageCleanupInterval, 3600.5)
    }
    
    func testInitWithCustomPolicies() {
        let customConnectPolicy = ConnectTimeoutPolicy()
        let customIdlePolicy = IdleActivityTimeoutPolicy()
        let customRetryPolicy = ClickstreamCourierRetryPolicy(isEnabled: false, delayMillis: 1000.0, maxRetryCount: 5)
        let customHttpRetryPolicy = ClickstreamCourierHTTPRetryPolicy(isEnabled: false, delayMillis: 2000.0, maxRetryCount: 2)
        
        let config = ClickstreamCourierConfig(
            connectTimeoutPolicy: customConnectPolicy,
            iddleActivityPolicy: customIdlePolicy,
            retryPolicy: customRetryPolicy,
            httpRetryPolicy: customHttpRetryPolicy
        )
        
        XCTAssertFalse(config.retryPolicy.isEnabled)
        XCTAssertEqual(config.retryPolicy.delayMillis, 1000.0)
        XCTAssertEqual(config.retryPolicy.maxRetryCount, 5)
        XCTAssertFalse(config.httpRetryPolicy.isEnabled)
        XCTAssertEqual(config.httpRetryPolicy.delayMillis, 2000.0)
        XCTAssertEqual(config.httpRetryPolicy.maxRetryCount, 2)
    }
    
    func testDecodingWithZeroValues() throws {
        let json = """
        {
            "ping_interval_ms": 0,
            "message_persistence_ttl_seconds": 0,
            "message_cleanup_interval": 0.0
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertEqual(config.pingIntervalMs, 0.0)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 0.0)
        XCTAssertEqual(config.messageCleanupInterval, 0.0)
    }
    
    func testInitWithAllCustomParameters() {
        let connectConfig = ClickstreamCourierConnectConfig()
        let connectTimeoutPolicy = ConnectTimeoutPolicy()
        let idlePolicy = IdleActivityTimeoutPolicy()
        let retryPolicy = ClickstreamCourierRetryPolicy()
        let httpRetryPolicy = ClickstreamCourierHTTPRetryPolicy()
        
        let config = ClickstreamCourierConfig(
            messageAdapter: [],
            connectConfig: connectConfig,
            connectTimeoutPolicy: connectTimeoutPolicy,
            iddleActivityPolicy: idlePolicy,
            retryPolicy: retryPolicy,
            httpRetryPolicy: httpRetryPolicy,
            pingIntervalMs: 250.0,
            isCleanSessionEnabled: true,
            messagePersistenceTTLSeconds: 43200.0,
            messageCleanupInterval: 5.0,
            shouldInitializeCoreDataPersistenceContext: true,
            isMessagePersistenceEnabled: true
        )
        
        XCTAssertTrue(config.messageAdapters.isEmpty)
        XCTAssertNotNil(config.connectConfig)
        XCTAssertNotNil(config.connectTimeoutPolicy)
        XCTAssertNotNil(config.iddleActivityPolicy)
        XCTAssertNotNil(config.retryPolicy)
        XCTAssertNotNil(config.httpRetryPolicy)
        XCTAssertEqual(config.pingIntervalMs, 250.0)
        XCTAssertTrue(config.isCleanSessionEnabled)
        XCTAssertEqual(config.messagePersistenceTTLSeconds, 43200.0)
        XCTAssertEqual(config.messageCleanupInterval, 5.0)
        XCTAssertTrue(config.shouldInitializeCoreDataPersistenceContext)
        XCTAssertTrue(config.isMessagePersistenceEnabled)
    }
    
    func testDecodingWithExtraUnknownFields() throws {
        let json = """
        {
            "message_adapters": ["json"],
            "unknown_field": "value",
            "extra_config": { "nested": true },
            "ping_interval_ms": 150,
            "deprecated_field": 999
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertEqual(config.messageAdapters.count, 1)
        XCTAssertEqual(config.pingIntervalMs, 150.0)
        XCTAssertFalse(config.isMessagePersistenceEnabled)
    }
    
    func testDecodingWithDuplicateAdapters() throws {
        let json = """
        {
            "message_adapters": ["json", "json", "data", "json"]
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        XCTAssertEqual(config.messageAdapters.count, 4)
    }
    
    func testDecodingWithFloatingPointBooleans() throws {
        let json = """
        {
            "clean_session_enabled": 1.0,
            "is_message_persistence_enabled": 0.0,
            "should_initialize_core_data_persistence_context": 2.5
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConfig.self, from: json)
        
        XCTAssertFalse(config.isCleanSessionEnabled)
        XCTAssertFalse(config.isMessagePersistenceEnabled)
        XCTAssertFalse(config.shouldInitializeCoreDataPersistenceContext)
    }
}
