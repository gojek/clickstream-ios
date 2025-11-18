//
//  ClickStreamCourierConstraints.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 18/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

/// Courier-based Clickstream constraints where it contains the same properties as `ClickstreamConstraints` except following:
/// - maxConnectionRetries
/// - maxConnectionRetryInterval
/// - maxRetryIntervalPostPrematureDisconnection
/// - maxRetriesPostPrematureDisconnection
/// - maxPingInterval: TimeInterval
public struct ClickstreamCourierConstraints: ClickstreamConstraintsContract, Decodable {

    /// This array holds all priority configs.
    private(set) var priorities: [Priority]

    /// This is flag which determines whether the contained events be flushed when the app moves to background.
    private(set) var flushOnBackground: Bool

    /// Wait time for the connection termination
    private(set) var connectionTerminationTimerWaitTime: TimeInterval

    // Max retry interval for timimg out a batch
    private(set) var maxRequestAckTimeout: TimeInterval

    /// Max retires allowed batch
    private(set) var maxRetriesPerBatch: Int
    
    // Max retry cache size on disk and memory
    private(set) var maxRetryCacheSize: Int
    
    // Connection retry duration
    private(set) var connectionRetryDuration: TimeInterval

    /// This is flag which determines whether the contained events be flushed when the app is launched for the first time by the user
    var flushOnAppLaunch: Bool

    /// This is flag which determines whether the contained events be sent when the device's battery is more that it
    var minBatteryLevelPercent: Float

    public init(priorities: [Priority] = [Priority()],
                flushOnBackground: Bool = true,
                connectionTerminationTimerWaitTime: TimeInterval = 8,
                maxRequestAckTimeout: TimeInterval = 6,
                maxRetriesPerBatch: Int = 20,
                maxRetryCacheSize: Int = 5000000,
                connectionRetryDuration: TimeInterval = 3,
                flushOnAppLaunch: Bool = false,
                minBatteryLevelPercent: Float = 10) {
        self.priorities = priorities
        self.flushOnBackground = flushOnBackground
        self.connectionTerminationTimerWaitTime = connectionTerminationTimerWaitTime
        self.maxRequestAckTimeout = maxRequestAckTimeout
        self.maxRetriesPerBatch = maxRetriesPerBatch
        self.maxRetryCacheSize = maxRetryCacheSize
        self.connectionRetryDuration = connectionRetryDuration
        self.flushOnAppLaunch = flushOnAppLaunch
        self.minBatteryLevelPercent = minBatteryLevelPercent
    }

    enum CodingKeys: String, CodingKey {
        case priorities
        case flushOnBackground
        case connectionTerminationTimerWaitTime
        case maxRequestAckTimeout
        case maxRetriesPerBatch
        case maxRetryCacheSize
        case connectionRetryDuration
        case flushOnAppLaunch
        case minBatteryLevelPercent
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        priorities = try container.decodeIfPresent([Priority].self, forKey: .priorities) ?? [Priority()]
        flushOnBackground = try container.decodeIfPresent(Bool.self, forKey: .flushOnBackground) ?? true
        connectionTerminationTimerWaitTime = try container.decodeIfPresent(TimeInterval.self, forKey: .connectionTerminationTimerWaitTime) ?? 8
        maxRequestAckTimeout = try container.decodeIfPresent(TimeInterval.self, forKey: .maxRequestAckTimeout) ?? 6
        maxRetriesPerBatch = try container.decodeIfPresent(Int.self, forKey: .maxRetriesPerBatch) ?? 20
        maxRetryCacheSize = try container.decodeIfPresent(Int.self, forKey: .maxRetryCacheSize) ?? 5000000
        connectionRetryDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .connectionRetryDuration) ?? 3
        flushOnAppLaunch = try container.decodeIfPresent(Bool.self, forKey: .flushOnAppLaunch) ?? false
        minBatteryLevelPercent = try container.decodeIfPresent(Float.self, forKey: .minBatteryLevelPercent) ?? 10
    }
}
