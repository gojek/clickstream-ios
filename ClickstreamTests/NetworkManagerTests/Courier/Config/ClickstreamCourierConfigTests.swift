//
//  ClickstreamCourierClientConfigTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 15/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import CourierMQTT

class ClickstreamCourierClientConfigTests: XCTestCase {
    
    func testDefaultInitialization() {
        let config = ClickstreamCourierClientConfig()
        
        XCTAssertTrue(config.courierMessageAdapter.isEmpty)
        XCTAssertEqual(config.courierPingIntervalMillis, 30)
        XCTAssertTrue(config.courierAuthTimeoutEnabled)
        XCTAssertEqual(config.courierAuthTimeoutIntervalSecs, 20)
        XCTAssertEqual(config.courierAutoReconnectIntervalSecs, 5)
        XCTAssertEqual(config.courierAutoReconnectMaxIntervalSecs, 10)
        XCTAssertEqual(config.courierTokenCacheType, 2)
        XCTAssertTrue(config.courierTokenCacheExpiryEnabled)
        XCTAssertEqual(config.courierTokenExpiryMins, 360)
        XCTAssertEqual(config.courierMessageCleanupInterval, 10)
        XCTAssertFalse(config.courierIsCleanSessionEnabled)
        XCTAssertFalse(config.courierMessagePersistenceEnabled)
        XCTAssertEqual(config.courierMessagePersistenceTTLSecs, 86400)
        XCTAssertFalse(config.courierInitCoreDataPersistenceContextEnabled)
        XCTAssertFalse(config.courierConnectTimeoutPolicyEnabled)
        XCTAssertEqual(config.courierConnectTimeoutPolicyIntervalMillis, 16)
        XCTAssertEqual(config.courierConnectTimeoutPolicyMaxRetryCount, 10)
        XCTAssertFalse(config.courierInactivityPolicyEnabled)
        XCTAssertEqual(config.courierInactivityPolicyIntervalMillis, 12)
        XCTAssertEqual(config.courierInactivityPolicyTimeoutMillis, 10)
        XCTAssertEqual(config.courierInactivityPolicyReadTimeoutMillis, 40)
    }
    
    func testCustomInitialization() {
        let customAdapters: [MessageAdapter] = []
        let config = ClickstreamCourierClientConfig(
            courierMessageAdapter: customAdapters,
            courierPingIntervalMillis: 60,
            courierAuthTimeoutEnabled: false,
            courierAuthTimeoutIntervalSecs: 30,
            courierAutoReconnectIntervalSecs: 10,
            courierAutoReconnectMaxIntervalSecs: 20,
            courierTokenCacheType: 1,
            courierTokenCacheExpiryEnabled: false,
            courierTokenExpiryMins: 720,
            courierMessageCleanupInterval: 20,
            courierIsCleanSessionEnabled: true,
            courierMessagePersistenceEnabled: true,
            courierMessagePersistenceTTLSecs: 172800,
            courierInitCoreDataPersistenceContextEnabled: true,
            courierConnectTimeoutPolicyEnabled: true,
            courierConnectTimeoutPolicyIntervalMillis: 32,
            courierConnectTimeoutPolicyMaxRetryCount: 20,
            courierInactivityPolicyEnabled: true,
            courierInactivityPolicyIntervalMillis: 24,
            courierInactivityPolicyTimeoutMillis: 20,
            courierInactivityPolicyReadTimeoutMillis: 80
        )
        
        XCTAssertEqual(config.courierMessageAdapter.count, 0)
        XCTAssertEqual(config.courierPingIntervalMillis, 60)
        XCTAssertFalse(config.courierAuthTimeoutEnabled)
        XCTAssertEqual(config.courierAuthTimeoutIntervalSecs, 30)
        XCTAssertEqual(config.courierAutoReconnectIntervalSecs, 10)
        XCTAssertEqual(config.courierAutoReconnectMaxIntervalSecs, 20)
        XCTAssertEqual(config.courierTokenCacheType, 1)
        XCTAssertFalse(config.courierTokenCacheExpiryEnabled)
        XCTAssertEqual(config.courierTokenExpiryMins, 720)
        XCTAssertEqual(config.courierMessageCleanupInterval, 20)
        XCTAssertTrue(config.courierIsCleanSessionEnabled)
        XCTAssertTrue(config.courierMessagePersistenceEnabled)
        XCTAssertEqual(config.courierMessagePersistenceTTLSecs, 172800)
        XCTAssertTrue(config.courierInitCoreDataPersistenceContextEnabled)
        XCTAssertTrue(config.courierConnectTimeoutPolicyEnabled)
        XCTAssertEqual(config.courierConnectTimeoutPolicyIntervalMillis, 32)
        XCTAssertEqual(config.courierConnectTimeoutPolicyMaxRetryCount, 20)
        XCTAssertTrue(config.courierInactivityPolicyEnabled)
        XCTAssertEqual(config.courierInactivityPolicyIntervalMillis, 24)
        XCTAssertEqual(config.courierInactivityPolicyTimeoutMillis, 20)
        XCTAssertEqual(config.courierInactivityPolicyReadTimeoutMillis, 80)
    }
    
    func testPartialCustomInitialization() {
        let config = ClickstreamCourierClientConfig(
            courierPingIntervalMillis: 45,
            courierTokenExpiryMins: 180
        )
        
        XCTAssertEqual(config.courierPingIntervalMillis, 45)
        XCTAssertEqual(config.courierTokenExpiryMins, 180)
        XCTAssertEqual(config.courierAuthTimeoutIntervalSecs, 20)
        XCTAssertTrue(config.courierAuthTimeoutEnabled)
    }
    
    func testBoundaryValues() {
        let config = ClickstreamCourierClientConfig(
            courierPingIntervalMillis: 0,
            courierTokenExpiryMins: 0,
            courierMessagePersistenceTTLSecs: 0
        )
        
        XCTAssertEqual(config.courierPingIntervalMillis, 0)
        XCTAssertEqual(config.courierTokenExpiryMins, 0)
        XCTAssertEqual(config.courierMessagePersistenceTTLSecs, 0)
    }
    
    func testNegativeValues() {
        let config = ClickstreamCourierClientConfig(
            courierPingIntervalMillis: -10,
            courierAutoReconnectIntervalSecs: -5,
            courierConnectTimeoutPolicyMaxRetryCount: -1
        )
        
        XCTAssertEqual(config.courierPingIntervalMillis, -10)
        XCTAssertEqual(config.courierAutoReconnectIntervalSecs, -5)
        XCTAssertEqual(config.courierConnectTimeoutPolicyMaxRetryCount, -1)
    }
    
    func testLargeValues() {
        let config = ClickstreamCourierClientConfig(
            courierPingIntervalMillis: Int.max,
            courierTokenExpiryMins: Int.max,
            courierMessagePersistenceTTLSecs: Int.max
        )
        
        XCTAssertEqual(config.courierPingIntervalMillis, Int.max)
        XCTAssertEqual(config.courierTokenExpiryMins, Int.max)
        XCTAssertEqual(config.courierMessagePersistenceTTLSecs, Int.max)
    }
    
    func testAllBooleansCombinations() {
        let configAllTrue = ClickstreamCourierClientConfig(
            courierAuthTimeoutEnabled: true,
            courierTokenCacheExpiryEnabled: true,
            courierIsCleanSessionEnabled: true,
            courierMessagePersistenceEnabled: true,
            courierInitCoreDataPersistenceContextEnabled: true,
            courierConnectTimeoutPolicyEnabled: true,
            courierInactivityPolicyEnabled: true
        )
        
        XCTAssertTrue(configAllTrue.courierAuthTimeoutEnabled)
        XCTAssertTrue(configAllTrue.courierTokenCacheExpiryEnabled)
        XCTAssertTrue(configAllTrue.courierIsCleanSessionEnabled)
        XCTAssertTrue(configAllTrue.courierMessagePersistenceEnabled)
        XCTAssertTrue(configAllTrue.courierInitCoreDataPersistenceContextEnabled)
        XCTAssertTrue(configAllTrue.courierConnectTimeoutPolicyEnabled)
        XCTAssertTrue(configAllTrue.courierInactivityPolicyEnabled)
        
        let configAllFalse = ClickstreamCourierClientConfig(
            courierAuthTimeoutEnabled: false,
            courierTokenCacheExpiryEnabled: false,
            courierIsCleanSessionEnabled: false,
            courierMessagePersistenceEnabled: false,
            courierInitCoreDataPersistenceContextEnabled: false,
            courierConnectTimeoutPolicyEnabled: false,
            courierInactivityPolicyEnabled: false
        )
        
        XCTAssertFalse(configAllFalse.courierAuthTimeoutEnabled)
        XCTAssertFalse(configAllFalse.courierTokenCacheExpiryEnabled)
        XCTAssertFalse(configAllFalse.courierIsCleanSessionEnabled)
        XCTAssertFalse(configAllFalse.courierMessagePersistenceEnabled)
        XCTAssertFalse(configAllFalse.courierInitCoreDataPersistenceContextEnabled)
        XCTAssertFalse(configAllFalse.courierConnectTimeoutPolicyEnabled)
        XCTAssertFalse(configAllFalse.courierInactivityPolicyEnabled)
    }
}
