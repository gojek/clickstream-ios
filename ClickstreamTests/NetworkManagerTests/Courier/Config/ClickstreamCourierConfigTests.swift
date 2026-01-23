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
        XCTAssertFalse(config.courierConnectPolicy.isEnabled)
        XCTAssertEqual(config.courierConnectPolicy.intervalSecs, 15)
        XCTAssertEqual(config.courierConnectPolicy.timeoutSecs, 10)
        XCTAssertFalse(config.courierInactivityPolicy.isEnabled)
        XCTAssertEqual(config.courierInactivityPolicy.intervalSecs, 12)
        XCTAssertEqual(config.courierInactivityPolicy.timeoutSecs, 10)
        XCTAssertEqual(config.courierInactivityPolicy.readTimeoutSecs, 40)
        XCTAssertEqual(config.courierHealthConfig.pubSubEventProbability, 0)
        XCTAssertEqual(config.courierHealthConfig.csTrackingHealthEventsEnabled, false)
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
            courierConnectPolicy: .init(isEnabled: true, intervalSecs: 32, timeoutSecs: 20),
            courierInactivityPolicy: .init(isEnabled: true, intervalSecs: 24, timeoutSecs: 20, readTimeoutSecs: 80),
            courierHealthConfig: .init(pubSubEventProbability: 50, csTrackingHealthEventsEnabled: false)
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
        XCTAssertTrue(config.courierConnectPolicy.isEnabled)
        XCTAssertEqual(config.courierConnectPolicy.intervalSecs, 32)
        XCTAssertEqual(config.courierConnectPolicy.timeoutSecs, 20)
        XCTAssertTrue(config.courierInactivityPolicy.isEnabled)
        XCTAssertEqual(config.courierInactivityPolicy.intervalSecs, 24)
        XCTAssertEqual(config.courierInactivityPolicy.timeoutSecs, 20)
        XCTAssertEqual(config.courierInactivityPolicy.readTimeoutSecs, 80)
        XCTAssertEqual(config.courierHealthConfig.pubSubEventProbability, 50)
        XCTAssertFalse(config.courierHealthConfig.csTrackingHealthEventsEnabled)
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
            courierConnectPolicy: .init(timeoutSecs: -1),
            courierHealthConfig: .init(pubSubEventProbability: -99)
        )
        
        XCTAssertEqual(config.courierPingIntervalMillis, -10)
        XCTAssertEqual(config.courierAutoReconnectIntervalSecs, -5)
        XCTAssertEqual(config.courierConnectPolicy.timeoutSecs, -1)
        XCTAssertEqual(config.courierHealthConfig.pubSubEventProbability, -99)
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
            courierConnectPolicy: .init(isEnabled: true),
            courierInactivityPolicy: .init(isEnabled: true)
        )
        
        XCTAssertTrue(configAllTrue.courierAuthTimeoutEnabled)
        XCTAssertTrue(configAllTrue.courierTokenCacheExpiryEnabled)
        XCTAssertTrue(configAllTrue.courierIsCleanSessionEnabled)
        XCTAssertTrue(configAllTrue.courierMessagePersistenceEnabled)
        XCTAssertTrue(configAllTrue.courierInitCoreDataPersistenceContextEnabled)
        XCTAssertTrue(configAllTrue.courierConnectPolicy.isEnabled)
        XCTAssertTrue(configAllTrue.courierInactivityPolicy.isEnabled)
        
        let configAllFalse = ClickstreamCourierClientConfig(
            courierAuthTimeoutEnabled: false,
            courierTokenCacheExpiryEnabled: false,
            courierIsCleanSessionEnabled: false,
            courierMessagePersistenceEnabled: false,
            courierInitCoreDataPersistenceContextEnabled: false,
            courierConnectPolicy: .init(isEnabled: false),
            courierInactivityPolicy: .init(isEnabled: false),
            courierHealthConfig: .init(csTrackingHealthEventsEnabled: false)
        )
        
        XCTAssertFalse(configAllFalse.courierAuthTimeoutEnabled)
        XCTAssertFalse(configAllFalse.courierTokenCacheExpiryEnabled)
        XCTAssertFalse(configAllFalse.courierIsCleanSessionEnabled)
        XCTAssertFalse(configAllFalse.courierMessagePersistenceEnabled)
        XCTAssertFalse(configAllFalse.courierInitCoreDataPersistenceContextEnabled)
        XCTAssertFalse(configAllFalse.courierConnectPolicy.isEnabled)
        XCTAssertFalse(configAllFalse.courierInactivityPolicy.isEnabled)
        XCTAssertFalse(configAllFalse.courierHealthConfig.csTrackingHealthEventsEnabled)
    }
}
