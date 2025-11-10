//
//  ClickstreamCourierConfig.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 10/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierMQTT

public struct ClickstreamCourierConfig: Decodable {
    public let messageAdapters: [MessageAdapter]

    public let connectConfig: ClickstreamCourierConnectConfig
    public let connectTimeoutPolicy: IConnectTimeoutPolicy
    public let iddleActivityPolicy: IdleActivityTimeoutPolicyProtocol

    public let pingIntervalMs: TimeInterval
    public var pollingIntervalMs: TimeInterval
    public var pollingMaxRetryCount: Int
    public let isCleanSessionEnabled: Bool
    public let messagePersistenceTTLSeconds: TimeInterval
    public let messageCleanupInterval: TimeInterval
    public let shouldInitializeCoreDataPersistenceContext: Bool
    public let isMessagePersistenceEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case messageAdapters = "message_adapters"
        case connectConfig = "connect_config"
        case connectTimeoutPolicy = "connect_timeout_policy"
        case iddleActivityPolicy = "iddle_activity_policy"
        case pingIntervalMs = "ping_interval_ms"
        case pollingIntervalMs = "polling_interval_ms"
        case pollingMaxRetryCount = "polling_max_retry_count"
        case isCleanSessionEnabled = "clean_session_enabled"
        case messagePersistenceTTLSeconds = "message_persistence_ttl_seconds"
        case messageCleanupInterval = "message_cleanup_interval"
        case isMessagePersistenceEnabled = "is_message_persistence_enabled"
        case shouldInitializeCoreDataPersistenceContext = "should_initialize_core_data_persistence_context"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let adapters = try? container.decodeIfPresent([String].self, forKey: .messageAdapters) {
            messageAdapters = adapters.compactMap {
                guard let type = CourierMessageAdapterType(rawValue: $0) else { return nil }
                return CourierMessageAdapterType.mapped(from: type)
            }
        } else {
            messageAdapters = []
        }

        if let config = try? container.decodeIfPresent(ClickstreamCourierConnectConfig.self, forKey: .connectConfig) {
            connectConfig = config
        } else {
            connectConfig = ClickstreamCourierConnectConfig()
        }

        if let connectPolicy = try? container.decodeIfPresent(CourierConnectTimeoutPolicy.self, forKey: .connectTimeoutPolicy) {
            connectTimeoutPolicy = connectPolicy
        } else {
            connectTimeoutPolicy = ConnectTimeoutPolicy()
        }

        if let iddlePolicy = try? container.decodeIfPresent(CourierIdleActivityTimeoutPolicy.self, forKey: .iddleActivityPolicy) {
            iddleActivityPolicy = iddlePolicy
        } else {
            iddleActivityPolicy = IdleActivityTimeoutPolicy()
        }

        pingIntervalMs = container.decodeTimeIntervalIfPresent(forKey: .pingIntervalMs) ?? 10
        pollingIntervalMs = container.decodeTimeIntervalIfPresent(forKey: .pollingIntervalMs) ?? 200.0
        pollingMaxRetryCount = (try? container.decodeIfPresent(Int.self, forKey: .pollingMaxRetryCount)) ?? 3
        isCleanSessionEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .isCleanSessionEnabled)) ?? false
        messagePersistenceTTLSeconds = container.decodeTimeIntervalIfPresent(forKey: .messagePersistenceTTLSeconds) ?? 86400.0
        messageCleanupInterval = container.decodeTimeIntervalIfPresent(forKey: .messageCleanupInterval) ?? 10
        shouldInitializeCoreDataPersistenceContext = (try? container.decodeIfPresent(Bool.self, forKey: .shouldInitializeCoreDataPersistenceContext)) ?? false
        isMessagePersistenceEnabled = (try? container.decode(Bool.self, forKey: .isMessagePersistenceEnabled)) ?? false
    }

    public init(messageAdapter: [MessageAdapter] = [],
                connectConfig: ClickstreamCourierConnectConfig = ClickstreamCourierConnectConfig(),
                connectTimeoutPolicy: IConnectTimeoutPolicy = ConnectTimeoutPolicy(),
                iddleActivityPolicy: IdleActivityTimeoutPolicyProtocol = IdleActivityTimeoutPolicy(),
                pingIntervalMs: TimeInterval = 30.0,
                pollingIntervalMs: TimeInterval = 200.0,
                pollingMaxRetryCount: Int = 3,
                isCleanSessionEnabled: Bool = false,
                messagePersistenceTTLSeconds: TimeInterval = 86400.0,
                messageCleanupInterval: TimeInterval = 10.0,
                shouldInitializeCoreDataPersistenceContext: Bool = false,
                isMessagePersistenceEnabled: Bool = false) {

        self.messageAdapters = messageAdapter
        self.connectConfig = connectConfig
        self.connectTimeoutPolicy = connectTimeoutPolicy
        self.iddleActivityPolicy = iddleActivityPolicy
        self.pingIntervalMs = pingIntervalMs
        self.pollingIntervalMs = pollingIntervalMs
        self.pollingMaxRetryCount = pollingMaxRetryCount
        self.isCleanSessionEnabled = isCleanSessionEnabled
        self.messagePersistenceTTLSeconds = messagePersistenceTTLSeconds
        self.messageCleanupInterval = messageCleanupInterval
        self.shouldInitializeCoreDataPersistenceContext = shouldInitializeCoreDataPersistenceContext
        self.isMessagePersistenceEnabled = isMessagePersistenceEnabled
    }
}
