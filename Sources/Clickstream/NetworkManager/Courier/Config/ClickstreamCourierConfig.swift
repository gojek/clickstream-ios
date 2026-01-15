//
//  ClickstreamCourierClientConfig.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 10/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierMQTT


public struct ClickstreamCourierClientConfig {

    public let courierMessageAdapter: [MessageAdapter]
    public let courierPingIntervalMillis: Int
    public let courierAuthTimeoutEnabled: Bool
    public let courierAuthTimeoutIntervalSecs: Int
    public let courierAutoReconnectIntervalSecs: Int
    public let courierAutoReconnectMaxIntervalSecs: Int
    public let courierTokenCacheType: Int
    public let courierTokenCacheExpiryEnabled: Bool
    public let courierTokenExpiryMins: Int
    public let courierMessageCleanupInterval: Int
    public let courierIsCleanSessionEnabled: Bool
    public let courierMessagePersistenceEnabled: Bool
    public let courierMessagePersistenceTTLSecs: Int
    public let courierInitCoreDataPersistenceContextEnabled: Bool
    public let courierConnectTimeoutPolicyEnabled: Bool
    public let courierConnectTimeoutPolicyIntervalMillis: Int
    public let courierConnectTimeoutPolicyMaxRetryCount: Int
    public let courierInactivityPolicyEnabled: Bool
    public let courierInactivityPolicyIntervalMillis: Int
    public let courierInactivityPolicyTimeoutMillis: Int
    public let courierInactivityPolicyReadTimeoutMillis: Int
    public let courierPubSubEventProbability: Int

    public init(
        courierMessageAdapter: [MessageAdapter] = [],
        courierPingIntervalMillis: Int = 30,
        courierAuthTimeoutEnabled: Bool = true,
        courierAuthTimeoutIntervalSecs: Int = 20,
        courierAutoReconnectIntervalSecs: Int = 5,
        courierAutoReconnectMaxIntervalSecs: Int = 10,
        courierTokenCacheType: Int = 2,
        courierTokenCacheExpiryEnabled: Bool = true,
        courierTokenExpiryMins: Int = 360,
        courierMessageCleanupInterval: Int = 10,
        courierIsCleanSessionEnabled: Bool = false,
        courierMessagePersistenceEnabled: Bool = false,
        courierMessagePersistenceTTLSecs: Int = 86400,
        courierInitCoreDataPersistenceContextEnabled: Bool = false,
        courierConnectTimeoutPolicyEnabled: Bool = false,
        courierConnectTimeoutPolicyIntervalMillis: Int = 16,
        courierConnectTimeoutPolicyMaxRetryCount: Int = 10,
        courierInactivityPolicyEnabled: Bool = false,
        courierInactivityPolicyIntervalMillis: Int = 12,
        courierInactivityPolicyTimeoutMillis: Int = 10,
        courierInactivityPolicyReadTimeoutMillis: Int = 40,
        courierPubSubEventProbability: Int = 99
    ) {
        self.courierMessageAdapter = courierMessageAdapter
        self.courierPingIntervalMillis = courierPingIntervalMillis
        self.courierAuthTimeoutEnabled = courierAuthTimeoutEnabled
        self.courierAuthTimeoutIntervalSecs = courierAuthTimeoutIntervalSecs
        self.courierAutoReconnectIntervalSecs = courierAutoReconnectIntervalSecs
        self.courierAutoReconnectMaxIntervalSecs = courierAutoReconnectMaxIntervalSecs
        self.courierTokenCacheType = courierTokenCacheType
        self.courierTokenCacheExpiryEnabled = courierTokenCacheExpiryEnabled
        self.courierTokenExpiryMins = courierTokenExpiryMins
        self.courierMessageCleanupInterval = courierMessageCleanupInterval
        self.courierIsCleanSessionEnabled = courierIsCleanSessionEnabled
        self.courierMessagePersistenceEnabled = courierMessagePersistenceEnabled
        self.courierMessagePersistenceTTLSecs = courierMessagePersistenceTTLSecs
        self.courierInitCoreDataPersistenceContextEnabled = courierInitCoreDataPersistenceContextEnabled
        self.courierConnectTimeoutPolicyEnabled = courierConnectTimeoutPolicyEnabled
        self.courierConnectTimeoutPolicyIntervalMillis = courierConnectTimeoutPolicyIntervalMillis
        self.courierConnectTimeoutPolicyMaxRetryCount = courierConnectTimeoutPolicyMaxRetryCount
        self.courierInactivityPolicyEnabled = courierInactivityPolicyEnabled
        self.courierInactivityPolicyIntervalMillis = courierInactivityPolicyIntervalMillis
        self.courierInactivityPolicyTimeoutMillis = courierInactivityPolicyTimeoutMillis
        self.courierInactivityPolicyReadTimeoutMillis = courierInactivityPolicyReadTimeoutMillis
        self.courierPubSubEventProbability = courierPubSubEventProbability
    }
}
