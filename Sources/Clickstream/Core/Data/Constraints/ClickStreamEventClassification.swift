//
//  ClickstreamEventClassification.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 27/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

/// Holds the Event classification for Clickstream.
public struct ClickstreamEventClassification {
    
    /// Holds all the eventTypes
    private(set) var eventTypes: [EventClassifier]
    
    /// Returns an instance of ClickstreamEventClassification
    public init(eventTypes: [EventClassifier] = [EventClassifier(identifier: "realTime", eventNames: [], csEventNames: []),EventClassifier(identifier: "instant", eventNames: [], csEventNames: [])]) {
        self.eventTypes = eventTypes
    }
    
    public struct EventClassifier {
        
        /// To identify the events. And map between priorities and event names.
        private(set) var identifier: String
        
        /// List of event names under a given category.
        private(set) var eventNames: [String]
        
        private(set) var csEventNames: [String]
        
        public init(identifier: String, eventNames: [String], csEventNames: [String]) {
            self.identifier = identifier
            self.eventNames = eventNames
            self.csEventNames = csEventNames
        }
    }
}

//{
//  "properties": {
//    "event_classification_enabled": true,
//    "classification_configs": "[{\"identifier\":\"Product\",\"event_names\":{},\"protos\":[\"Page\",\"Component\",\"NotificationInfo\",\"AppLifeCycle\",\"CallSupportToken\",\"ChangePayment\",\"LocationInfo\",\"MiniApp\",\"InboxInfo\",\"RatingInfo\",\"Upsell\",\"DriverOrder\",\"Navic\",\"Estimate\",\"UserAccount\",\"SnippetInfo\",\"Order\",\"CallingInfo\",\"Chat\",\"AdCardEvent\"],\"ticker_interval_millis\":5000,\"qos_level\":1,\"priority\":0,\"persistence_type\":\"DISK\",\"http_fallback_enabled\":true,\"health_tracking_enabled\":false,\"batch_size_in_bytes\":50000,\"batch_size_event_count\":50,\"ttl_expiry_time\":180,\"active\":true,\"bg_flush_enabled\":true},{\"identifier\":\"Dev\",\"event_names\":{},\"protos\":[\"ExperimentRun\",\"AppHealth\",\"Config\",\"DroppedPropertiesBatch\",\"Trace\",\"S4Health\",\"APIHealth\",\"AppAttributes\",\"Health\",\"Localization\",\"RiskTelemetry\",\"PubSubHealth\"],\"ticker_interval_millis\":60000,\"qos_level\":0,\"priority\":1,\"persistence_type\":\"MEMORY\",\"http_fallback_enabled\":false,\"batch_size_in_bytes\":50000,\"batch_size_event_count\":50,\"ttl_expiry_time\":180,\"active\":true}]"
//  }
//}

/// Top-level remote-config payload that carries classification settings for courier event routing.
///
/// The wire format wraps the actual settings inside a `properties` object, where
/// `classification_configs` is delivered as a JSON-encoded string rather than a nested array.
public struct EventClassificationRemoteConfig: Codable {

    /// Classification settings extracted from the remote-config envelope.
    public let properties: Properties

    /// Inner payload holding the classification toggle and the list of classification entries.
    ///
    /// - Note: `classification_configs` is transmitted as a JSON string; this type transparently
    ///   decodes and re-encodes it to/from `[ClassificationConfig]`.
    public struct Properties: Codable {

        /// Enables classification-based scheduling when true.
        public let isClassificationEnabled: Bool

        /// Classification entries used to resolve event routing and behavior.
        public let configs: [ClassificationConfig]

        enum CodingKeys: String, CodingKey {
            case isClassificationEnabled = "event_classification_enabled"
            case configs = "classification_configs"
        }

        public init(isClassificationEnabled: Bool, configs: [ClassificationConfig]) {
            self.isClassificationEnabled = isClassificationEnabled
            self.configs = configs
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.isClassificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .isClassificationEnabled) ?? false

            // classification_configs arrives as a JSON-encoded string, decode it into the array.
            let configsString = try container.decode(String.self, forKey: .configs)
            guard let data = configsString.data(using: .utf8) else {
                throw DecodingError.dataCorruptedError(forKey: .configs,
                                                       in: container,
                                                       debugDescription: "classification_configs is not valid UTF-8")
            }
            self.configs = try JSONDecoder().decode([ClassificationConfig].self, from: data)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(isClassificationEnabled, forKey: .isClassificationEnabled)

            // Re-serialize the array back to a JSON string to match the wire format.
            let data = try JSONEncoder().encode(configs)
            guard let configsString = String(data: data, encoding: .utf8) else {
                throw EncodingError.invalidValue(
                    configs,
                    EncodingError.Context(codingPath: [CodingKeys.configs],
                                          debugDescription: "Failed to encode classification_configs as UTF-8 string")
                )
            }
            try container.encode(configsString, forKey: .configs)
        }
    }

    /// Configuration for a single courier event classification.
    ///
    /// Each classification defines how a group of events (matched by `protos` or `eventNames`) is
    /// batched, persisted, and delivered over the courier channel.
    public struct ClassificationConfig: Codable {

        /// Unique identifier for this classification.
        public let classificationId: String

        /// List of proto type names whose events belong to this classification.
        public let protos: [String]

        /// Map of event category to list of event names for matching.
        public let eventNames: [String: [String]]

        /// Interval in milliseconds between batch dispatch attempts.
        public let tickerIntervalMillis: Int64

        /// Maximum batch payload size in bytes before forcing a flush.
        public let batchSizeInBytes: Int64

        /// Maximum number of events per batch before forcing a flush.
        public let batchSizeEventCount: Int

        /// MQTT QoS level (0 = at most once, 1 = at least once).
        public let qosLevel: Int

        /// Time-to-live (in days) for events in this classification.
        public let ttlExpiryTime: Int64

        /// Storage strategy for events.
        public let persistenceType: PersistenceType

        /// Dispatch priority; lower value means higher priority.
        public let priority: Int

        /// Whether to fall back to HTTP when courier is unavailable.
        public let isHttpFallbackEnabled: Bool

        /// Whether to fall back to courier when the primary channel fails.
        public let isCourierFallbackEnabled: Bool

        /// Whether health/diagnostic events are emitted for this classification.
        public let healthTracking: Bool

        /// Whether the classification flushes events while the app is backgrounded.
        public let backgroundFlushEnabled: Bool

        /// Whether this classification is currently active.
        public let isActive: Bool

        enum CodingKeys: String, CodingKey {
            case classificationId = "identifier"
            case protos
            case eventNames = "event_names"
            case tickerIntervalMillis = "ticker_interval_millis"
            case batchSizeInBytes = "batch_size_in_bytes"
            case batchSizeEventCount = "batch_size_event_count"
            case qosLevel = "qos_level"
            case ttlExpiryTime = "ttl_expiry_time"
            case persistenceType = "persistence_type"
            case priority
            case isHttpFallbackEnabled = "http_fallback_enabled"
            case isCourierFallbackEnabled = "courier_fallback_enabled"
            case healthTracking = "health_tracking_enabled"
            case backgroundFlushEnabled = "bg_flush_enabled"
            case isActive = "active"
        }

        public init(classificationId: String,
                    protos: [String] = [],
                    eventNames: [String: [String]] = [:],
                    tickerIntervalMillis: Int64 = 10000,
                    batchSizeInBytes: Int64 = 50000,
                    batchSizeEventCount: Int = 50,
                    qosLevel: Int = 0,
                    ttlExpiryTime: Int64 = 180,
                    persistenceType: PersistenceType = .disk,
                    priority: Int = .max,
                    isHttpFallbackEnabled: Bool = false,
                    isCourierFallbackEnabled: Bool = false,
                    healthTracking: Bool = false,
                    backgroundFlushEnabled: Bool = false,
                    isActive: Bool = true) {
            self.classificationId = classificationId
            self.protos = protos
            self.eventNames = eventNames
            self.tickerIntervalMillis = tickerIntervalMillis
            self.batchSizeInBytes = batchSizeInBytes
            self.batchSizeEventCount = batchSizeEventCount
            self.qosLevel = qosLevel
            self.ttlExpiryTime = ttlExpiryTime
            self.persistenceType = persistenceType
            self.priority = priority
            self.isHttpFallbackEnabled = isHttpFallbackEnabled
            self.isCourierFallbackEnabled = isCourierFallbackEnabled
            self.healthTracking = healthTracking
            self.backgroundFlushEnabled = backgroundFlushEnabled
            self.isActive = isActive
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.classificationId = try container.decode(String.self, forKey: .classificationId)
            self.protos = try container.decodeIfPresent([String].self, forKey: .protos) ?? []
            self.eventNames = try container.decodeIfPresent([String: [String]].self, forKey: .eventNames) ?? [:]
            self.tickerIntervalMillis = try container.decodeIfPresent(Int64.self, forKey: .tickerIntervalMillis) ?? 10000
            self.batchSizeInBytes = try container.decodeIfPresent(Int64.self, forKey: .batchSizeInBytes) ?? 50000
            self.batchSizeEventCount = try container.decodeIfPresent(Int.self, forKey: .batchSizeEventCount) ?? 50
            self.qosLevel = try container.decodeIfPresent(Int.self, forKey: .qosLevel) ?? 0
            self.ttlExpiryTime = try container.decodeIfPresent(Int64.self, forKey: .ttlExpiryTime) ?? 180
            self.persistenceType = try container.decodeIfPresent(PersistenceType.self, forKey: .persistenceType) ?? .disk
            self.priority = try container.decodeIfPresent(Int.self, forKey: .priority) ?? .max
            self.isHttpFallbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .isHttpFallbackEnabled) ?? false
            self.isCourierFallbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .isCourierFallbackEnabled) ?? false
            self.healthTracking = try container.decodeIfPresent(Bool.self, forKey: .healthTracking) ?? false
            self.backgroundFlushEnabled = try container.decodeIfPresent(Bool.self, forKey: .backgroundFlushEnabled) ?? false
            self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        }

        /// Identifier for the default (real-time) classification.
        public static let defaultClassificationId: String = "realTime"

        /// Persistence strategy for storing events belonging to a classification.
        ///
        /// `disk` survives process restarts; `memory` is faster but non-durable.
        public enum PersistenceType: String, Codable {
            case disk = "DISK"
            case memory = "MEMORY"
        }
    }
}


