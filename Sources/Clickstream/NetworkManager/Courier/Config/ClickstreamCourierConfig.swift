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
    public let retryPolicy: ClickstreamCourierRetryPolicy
    public let httpRetryPolicy: ClickstreamCourierHTTPRetryPolicy

    public let pingIntervalMs: TimeInterval
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
        case retryPolicy = "fallback_policy"
        case httpRetryPolicy = "http_fallback_policy"
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

        retryPolicy = ClickstreamCourierRetryPolicy()
        httpRetryPolicy = ClickstreamCourierHTTPRetryPolicy()
        pingIntervalMs = container.decodeTimeIntervalIfPresent(forKey: .pingIntervalMs) ?? 10
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
                retryPolicy: ClickstreamCourierRetryPolicy = ClickstreamCourierRetryPolicy(),
                httpRetryPolicy: ClickstreamCourierHTTPRetryPolicy = ClickstreamCourierHTTPRetryPolicy(),
                pingIntervalMs: TimeInterval = 30.0,
                isCleanSessionEnabled: Bool = false,
                messagePersistenceTTLSeconds: TimeInterval = 86400.0,
                messageCleanupInterval: TimeInterval = 10.0,
                shouldInitializeCoreDataPersistenceContext: Bool = false,
                isMessagePersistenceEnabled: Bool = false) {

        self.messageAdapters = messageAdapter
        self.connectConfig = connectConfig
        self.connectTimeoutPolicy = connectTimeoutPolicy
        self.iddleActivityPolicy = iddleActivityPolicy
        self.retryPolicy = retryPolicy
        self.httpRetryPolicy = httpRetryPolicy
        self.pingIntervalMs = pingIntervalMs
        self.isCleanSessionEnabled = isCleanSessionEnabled
        self.messagePersistenceTTLSeconds = messagePersistenceTTLSeconds
        self.messageCleanupInterval = messageCleanupInterval
        self.shouldInitializeCoreDataPersistenceContext = shouldInitializeCoreDataPersistenceContext
        self.isMessagePersistenceEnabled = isMessagePersistenceEnabled
    }
}

public struct ClickstreamCourierClientConfig: Decodable {
    public let disableReconnectOnAuthFailureIOS: Bool?
    public let disconnectOnBackground: Bool?
    public let policyResetTimeSeconds: Int?
    public let experimentConfigVersion: String?
    public let enableIdleTimeoutPolicyIOS: Bool?
    public let readTimeoutIOS: Int?
    public let integrationEnabled: Bool?
    public let eventProbability: Int?
    public let disconnectDelaySeconds: Int?
    public let pingExperimentVariant: Int?
    public let connectTimerIntervalIOS: Int?
    public let useBgFgNotificationIOS: Bool?
    public let enableAuthenticationTimeoutIOS: Bool?
    public let eventSamplingEnabled: Bool?
    public let connectTimeoutConfig: ConnectTimeoutConfig?
    public let activityCheckInterval: Int?
    public let tokenCachingMechanism: Int?
    public let enableConnectTimeoutPolicyIOS: Bool?
    public let messagesTrackingEnabled: Bool?
    public let subscriptionRetryConfig: SubscriptionRetryConfig?
    public let inactivityTimeoutIOS: Int?
    public let pingInterval: Int?
    public let chatCourierEventProbability: Int?
    public let readTimeoutSeconds: Int?
    public let idleTimerIntervalIOS: Int?
    public let disableDisconnectOnConnectionUnavailable: Bool?
    public let connectRetryConfig: ConnectRetryConfig?
    public let inactivityTimeoutSeconds: Int?
    public let customRetryPolicyEnabled: Bool?
    public let connectTimeoutIOS: Int?
    public let authenticationTimeoutIntervalIOS: Int?

    public struct ConnectTimeoutConfig: Decodable {
        public let sslHandshakeTimeout: Int?
        public let sslUpperBound: Int?
        public let tcpUpperBound: Int?
    }

    public struct SubscriptionRetryConfig: Decodable {
        public let maxRetryCount: Int?
    }

    public struct ConnectRetryConfig: Decodable {
        public let maxCount: Int?
        public let fixedTimeSecs: Int?
        public let randomTimeSecs: Int?
        public let maxTimeSecs: Int?
    }

    public enum CodingKeys: String, CodingKey {
        case disableReconnectOnAuthFailureIOS = "courier_disable_reconnect_on_auth_failure_ios"
        case disconnectOnBackground = "chat_courier_disconnect_on_background"
        case policyResetTimeSeconds = "courier_policy_reset_time_seconds"
        case experimentConfigVersion = "chat_experiment_config_version"
        case enableIdleTimeoutPolicyIOS = "courier_enable_idle_timeout_policy_ios"
        case readTimeoutIOS = "courier_read_timeout_ios"
        case integrationEnabled = "chat_courier_integration_enabled"
        case eventProbability = "courier_event_probability"
        case disconnectDelaySeconds = "courier_disconnect_delay_seconds"
        case pingExperimentVariant = "ping_experiment_variant"
        case connectTimerIntervalIOS = "courier_connect_timer_interval_ios"
        case useBgFgNotificationIOS = "courier_use_app_did_enter_bg_and_will_enter_fg_notification_ios"
        case enableAuthenticationTimeoutIOS = "courier_enable_authentication_timeout_ios"
        case eventSamplingEnabled = "courier_event_sampling_enabled"
        case connectTimeoutConfig = "courier_connect_timeout_config"
        case activityCheckInterval = "courier_activity_check_interval"
        case tokenCachingMechanism = "courier_token_caching_mechanism"
        case enableConnectTimeoutPolicyIOS = "courier_enable_connect_timeout_policy_ios"
        case messagesTrackingEnabled = "chat_messages_tracking_enabled"
        case subscriptionRetryConfig = "courier_subscription_retry_config"
        case inactivityTimeoutIOS = "courier_inactivity_timeout_ios"
        case pingInterval = "courier_ping_interval"
        case chatCourierEventProbability = "chat_courier_event_probability"
        case readTimeoutSeconds = "courier_read_timeout_seconds"
        case idleTimerIntervalIOS = "courier_idle_timer_interval_ios"
        case disableDisconnectOnConnectionUnavailable = "courier_disable_disconnect_on_connection_unavailable"
        case connectRetryConfig = "courier_connect_retry_config"
        case inactivityTimeoutSeconds = "courier_inactivity_timeout_seconds"
        case customRetryPolicyEnabled = "courier_custom_retry_policy_enabled"
        case connectTimeoutIOS = "courier_connect_timeout_ios"
        case authenticationTimeoutIntervalIOS = "courier_authentication_timeout_interval_ios"
    }
}
