//
//  ClassificationConfigResolution.swift
//  Clickstream
//
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

extension EventClassificationRemoteConfig.ClassificationConfig {

    /// Ticker interval expressed as a `TimeInterval` (seconds) for scheduler timers.
    var tickerIntervalSeconds: TimeInterval {
        TimeInterval(tickerIntervalMillis) / 1000.0
    }

    /// Computes the expiry date for an event belonging to this classification.
    /// - Parameter timestamp: The event's creation timestamp.
    /// - Returns: `timestamp` advanced by `ttlExpiryTime` days.
    func expiryDate(from timestamp: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: Int(ttlExpiryTime), to: timestamp) ?? timestamp
    }

    /// The default real-time classification used when no configured classification matches.
    ///
    /// Mirrors the Android `ClassificationConfig.fromCsCourierConfig` default: a disk-backed,
    /// real-time lane carrying events at QoS 1.
    static func defaultRealTime() -> EventClassificationRemoteConfig.ClassificationConfig {
        EventClassificationRemoteConfig.ClassificationConfig(
            classificationId: EventClassificationRemoteConfig.ClassificationConfig.defaultClassificationId,
            protos: [],
            eventNames: [:],
            tickerIntervalMillis: 10000,
            batchSizeInBytes: 50000,
            batchSizeEventCount: 50,
            qosLevel: 1,
            ttlExpiryTime: 180,
            persistenceType: .disk,
            priority: .max,
            isHttpFallbackEnabled: false,
            isCourierFallbackEnabled: false,
            healthTracking: false,
            backgroundFlushEnabled: true,
            isActive: true
        )
    }
}

extension EventClassificationRemoteConfig.Properties {

    /// Active classifications ordered by ascending `priority` (lower value = higher priority).
    var activeConfigsByPriority: [EventClassificationRemoteConfig.ClassificationConfig] {
        configs
            .filter { $0.isActive }
            .sorted { $0.priority < $1.priority }
    }

    /// Resolves the classification identifier for an event.
    ///
    /// Matching order mirrors the Android implementation:
    /// 1. By event name (against each classification's `eventNames` values), priority ascending.
    /// 2. By proto type name (against each classification's `protos`), priority ascending.
    /// 3. Falls back to the default real-time classification.
    ///
    /// - Parameters:
    ///   - protoName: The event's proto type name (e.g. `event.messageName`).
    ///   - eventName: The event's full event name.
    ///   - csEventName: The clickstream event name, when available.
    /// - Returns: The resolved classification identifier.
    func resolveClassificationId(protoName: String, eventName: String, csEventName: String?) -> String {
        let ordered = configs.sorted { $0.priority < $1.priority }

        for config in ordered {
            let names = config.eventNames.values.flatMap { $0 }
            if let csEventName, names.contains(csEventName) {
                return config.classificationId
            }
            if names.contains(eventName) {
                return config.classificationId
            }
        }

        let shortProtoName = protoName.components(separatedBy: ".").last ?? protoName
        for config in ordered {
            if config.protos.contains(protoName) || config.protos.contains(shortProtoName) {
                return config.classificationId
            }
        }

        return EventClassificationRemoteConfig.ClassificationConfig.defaultClassificationId
    }
}
