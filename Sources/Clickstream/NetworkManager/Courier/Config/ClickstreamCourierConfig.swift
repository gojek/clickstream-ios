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
    public let topics: [String: Int]
    public let messageAdapters: [CourierMessageAdapterType]

    public let autoReconnectInterval: TimeInterval
    public let maxAutoReconnectInterval: TimeInterval
    public let enableAuthenticationTimeout: Bool
    public let authenticationTimeoutInterval: TimeInterval

    public let connectConfig: ClickstreamCourierConnectConfig
    public let connectTimeoutPolicy: IConnectTimeoutPolicy
    public let iddleActivityPolicy: IdleActivityTimeoutPolicyProtocol

    public let messagePersistenceTTLSeconds: TimeInterval
    public let messageCleanupInterval: TimeInterval
    public let shouldInitializeCoreDataPersistenceContext: Bool
    public let isMessagePersistenceEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case topics
        case messageAdapters = "message_adapters"

        case autoReconnectInterval = "auto_reconnect_interval"
        case maxAutoReconnectInterval = "max_auto_reconnect_interval"
        case enableAuthenticationTimeout = "enable_authentication_timeout"
        case authenticationTimeoutInterval = "authentication_timeout_interval"
        
        case connectTimeoutPolicy = "connect_timeout_policy"
        case iddleActivityPolicy = "iddle_activity_policy"

        case messagePersistenceTTLSeconds = "message_persistence_ttl_seconds"
        case messageCleanupInterval = "message_cleanup_interval"

        case isMessagePersistenceEnabled = "is_message_persistence_enabled"
        case shouldInitializeCoreDataPersistenceContext = "should_initialize_core_data_persistence_context"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        topics = (try? container.decodeIfPresent([String: Int].self, forKey: .topics)) ?? [:]
        
        if let adapters = try? container.decodeIfPresent([String].self, forKey: .messageAdapters) {
            messageAdapters = adapters.compactMap { CourierMessageAdapterType(rawValue: $0) }
        } else {
            messageAdapters = []
        }

        isMessagePersistenceEnabled = (try? container.decode(Bool.self, forKey: .isMessagePersistenceEnabled)) ?? false

        autoReconnectInterval = container.decodeTimeIntervalIfPresent(forKey: .autoReconnectInterval) ?? 1.0
        maxAutoReconnectInterval = container.decodeTimeIntervalIfPresent(forKey: .maxAutoReconnectInterval) ?? 30.0
        enableAuthenticationTimeout = (try? container.decodeIfPresent(Bool.self, forKey: .enableAuthenticationTimeout)) ?? false
        authenticationTimeoutInterval = container.decodeTimeIntervalIfPresent(forKey: .authenticationTimeoutInterval) ?? 30.0

        if let config = try? container.decodeIfPresent(ClickstreamCourierConnectConfig.self, forKey: .authenticationTimeoutInterval) {
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

        messagePersistenceTTLSeconds = container.decodeTimeIntervalIfPresent(forKey: .messagePersistenceTTLSeconds) ?? 86400
        messageCleanupInterval = container.decodeTimeIntervalIfPresent(forKey: .messageCleanupInterval) ?? 10

        shouldInitializeCoreDataPersistenceContext = (try? container.decodeIfPresent(Bool.self, forKey: .shouldInitializeCoreDataPersistenceContext)) ?? false
    }

    public init(topics: [String: Int] = [:],
                messageAdapter: [CourierMessageAdapterType] = [],
                isMessagePersistenceEnabled: Bool = false,
                autoReconnectInterval: TimeInterval = 1,
                maxAutoReconnectInterval: TimeInterval = 30,
                authenticationTimeoutInterval: TimeInterval = 30,
                enableAuthenticationTimeout: Bool = false,
                connectConfig: ClickstreamCourierConnectConfig = ClickstreamCourierConnectConfig(),
                connectTimeoutPolicy: IConnectTimeoutPolicy = ConnectTimeoutPolicy(),
                iddleActivityPolicy: IdleActivityTimeoutPolicyProtocol = IdleActivityTimeoutPolicy(),
                messagePersistenceTTLSeconds: TimeInterval = 0,
                messageCleanupInterval: TimeInterval = 10,
                shouldInitializeCoreDataPersistenceContext: Bool = false) {

        self.topics = topics
        self.messageAdapters = messageAdapter
        self.isMessagePersistenceEnabled = isMessagePersistenceEnabled
        self.autoReconnectInterval = autoReconnectInterval
        self.maxAutoReconnectInterval = maxAutoReconnectInterval
        self.enableAuthenticationTimeout = enableAuthenticationTimeout
        self.authenticationTimeoutInterval = authenticationTimeoutInterval
        self.connectConfig = connectConfig
        self.connectTimeoutPolicy = connectTimeoutPolicy
        self.iddleActivityPolicy = iddleActivityPolicy
        self.messagePersistenceTTLSeconds = messagePersistenceTTLSeconds
        self.messageCleanupInterval = messageCleanupInterval
        self.shouldInitializeCoreDataPersistenceContext = shouldInitializeCoreDataPersistenceContext
    }
}
