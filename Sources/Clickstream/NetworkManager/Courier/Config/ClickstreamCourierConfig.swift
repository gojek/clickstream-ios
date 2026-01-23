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
    public let courierConnectPolicy: ClickstreamCourierConnectPolicy
    public let courierInactivityPolicy: ClickstreamCourierInactivityPolicy
    public let courierHealthConfig: ClickstreamCourierHealthConfig

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
        courierConnectPolicy: ClickstreamCourierConnectPolicy = .init(),
        courierInactivityPolicy: ClickstreamCourierInactivityPolicy = .init(),
        courierHealthConfig: ClickstreamCourierHealthConfig = .init()
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
        self.courierConnectPolicy = courierConnectPolicy
        self.courierInactivityPolicy = courierInactivityPolicy
        self.courierHealthConfig = courierHealthConfig
    }
}

public struct ClickstreamCourierConnectPolicy: Decodable {
    public let isEnabled: Bool
    public let intervalSecs: Int
    public let timeoutSecs: Int

    public init(isEnabled: Bool = false, intervalSecs: Int = 15, timeoutSecs: Int = 10) {
        self.isEnabled = isEnabled
        self.intervalSecs = intervalSecs
        self.timeoutSecs = timeoutSecs
    }
}

public struct ClickstreamCourierInactivityPolicy: Decodable {
    public let isEnabled: Bool
    public let intervalSecs: Int
    public let timeoutSecs: Int
    public let readTimeoutSecs: Int

    public init(isEnabled: Bool = false, intervalSecs: Int = 12, timeoutSecs: Int = 10, readTimeoutSecs: Int = 40) {
        self.isEnabled = isEnabled
        self.intervalSecs = intervalSecs
        self.timeoutSecs = timeoutSecs
        self.readTimeoutSecs = readTimeoutSecs
    }
}

public struct ClickstreamCourierHealthConfig: Decodable {
    public let pubSubEventProbability: Int
    public let csTrackingHealthEventsEnabled: Bool

    public init(pubSubEventProbability: Int = 0, csTrackingHealthEventsEnabled: Bool = false) {
        self.pubSubEventProbability = pubSubEventProbability
        self.csTrackingHealthEventsEnabled = csTrackingHealthEventsEnabled
    }
}
