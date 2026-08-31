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
    public let courierMessagePersistenceInMemoryEnabled: Bool
    public let courierMessagePersistenceTTLSecs: Int
    public let courierInitCoreDataPersistenceContextEnabled: Bool
    public let courierQoSType: Int
    public let fixCxxDestructCrash: Bool
    public let useSafeDeleteForNonSQLiteStore: Bool
    public let fixMultipleConnectionCrash: Bool

    /// Serialises every call into Courier's underlying `MQTTSession` onto the session's own
    /// queue, fixing the `-[MQTTSession subscribeToTopics:subscribeHandler:]` data race where
    /// an app-issued subscribe raced the re-subscribe driven by the session's CONNACK handling
    /// and corrupted the session's handler dictionaries.
    ///
    /// Read once by the host app and passed in here: Courier captures the value for the
    /// lifetime of the client, so changing it takes effect on the next Clickstream setup.
    public let serializeSessionAccess: Bool

    /// Refuses publishes once the Courier client has been torn down, instead of forwarding
    /// them into a destroyed client (a use-after-free that crashed in `objc_retain` reading
    /// the MQTT session, and in `objc_msgSend` inside `-[MQTTSession nextMsgId]`).
    ///
    /// Read once by the host app and passed in here: the value is captured for the lifetime
    /// of the courier handler, so changing it takes effect on the next Clickstream setup.
    public let fixPublishAfterDestroyCrash: Bool

    /// Publishes events to a placeholder-based topic instead of one carrying the explicit
    /// user id: the user-id (terminal) path segment of the topic supplied via
    /// `providePreAuthClientIdentifiers`/`providePostAuthClientIdentifiers` is replaced with
    /// Courier's `%u` placeholder, which the courier layer resolves to the MQTT connection's
    /// username at publish time.
    ///
    /// Mirrors clickstream-android's `CSCourierConfig.isTopicPlaceholderEnabled`. Requires a
    /// courier-iOS version with topic placeholder support.
    public let isTopicPlaceholderEnabled: Bool

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
        courierMessagePersistenceInMemoryEnabled: Bool = false,
        courierMessagePersistenceTTLSecs: Int = 86400,
        courierInitCoreDataPersistenceContextEnabled: Bool = false,
        courierQoSType: Int = 4,
        fixCxxDestructCrash: Bool = false,
        useSafeDeleteForNonSQLiteStore: Bool = false,
        fixMultipleConnectionCrash: Bool = false,
        fixPublishAfterDestroyCrash: Bool = false,
        serializeSessionAccess: Bool = false,
        isTopicPlaceholderEnabled: Bool = false,
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
        self.courierMessagePersistenceInMemoryEnabled = courierMessagePersistenceInMemoryEnabled
        self.courierMessagePersistenceTTLSecs = courierMessagePersistenceTTLSecs
        self.courierInitCoreDataPersistenceContextEnabled = courierInitCoreDataPersistenceContextEnabled
        self.courierQoSType = courierQoSType
        self.fixCxxDestructCrash = fixCxxDestructCrash
        self.useSafeDeleteForNonSQLiteStore = useSafeDeleteForNonSQLiteStore
        self.fixMultipleConnectionCrash = fixMultipleConnectionCrash
        self.fixPublishAfterDestroyCrash = fixPublishAfterDestroyCrash
        self.serializeSessionAccess = serializeSessionAccess
        self.isTopicPlaceholderEnabled = isTopicPlaceholderEnabled
        self.courierConnectPolicy = courierConnectPolicy
        self.courierInactivityPolicy = courierInactivityPolicy
        self.courierHealthConfig = courierHealthConfig
    }
}

/// Rewrites publish topics for `ClickstreamCourierClientConfig.isTopicPlaceholderEnabled`.
///
/// Android publishes to `clickstream/v2/{app-type}/{user-type}/%u` instead of
/// `clickstream/v2/{app-type}/{user-type}/{user-id}` when the flag is on. On iOS the host
/// app supplies the fully-built topic, so the equivalent is swapping its user-id (terminal)
/// path segment for the `%u` placeholder; courier-iOS resolves `%u` to the MQTT connection's
/// username when the message is published.
enum CourierTopicPlaceholder {

    static let userPlaceholder = "%u"

    /// Returns `topic` with its last path segment replaced by `%u`.
    /// An empty topic, or one already ending in `%u`, is returned unchanged.
    static func applyingUserPlaceholder(to topic: String) -> String {
        var segments = topic.components(separatedBy: "/")
        guard let last = segments.last, !last.isEmpty, last != userPlaceholder else {
            return topic
        }
        segments[segments.count - 1] = userPlaceholder
        return segments.joined(separator: "/")
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
