//
//  ClickstreamConstraints.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 07/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

/// Holds the constraints for clickstream.
public struct ClickstreamConstraints {
        
    /// Maximum number of retries for connection.
    private(set) var maxConnectionRetries: Int
    
    /// Maximum retry interval between two successive retries (seconds)
    private(set) var maxConnectionRetryInterval: TimeInterval
    
    /// Maximum retry interval post a premature network disconnection (seconds)
    private(set) var maxRetryIntervalPostPrematureDisconnection: TimeInterval
    
    /// Maximum number of retries post a premature network disconnection.
    private(set) var maxRetriesPostPrematureDisconnection: Int
    
    /// Max Pint Interval (seconds)
    private(set) var maxPingInterval: TimeInterval
    
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
    
    /// Returns an instance of ClickstreamConstraints
    public init(maxConnectionRetries: Int = 30, maxConnectionRetryInterval: TimeInterval = 30,
                maxRetryIntervalPostPrematureDisconnection: TimeInterval = 30, maxRetriesPostPrematureDisconnection: Int = 10,
                maxPingInterval: TimeInterval = 15, priorities: [Priority] = [Priority()],
                flushOnBackground: Bool = true, connectionTerminationTimerWaitTime: TimeInterval = 8,
                maxRequestAckTimeout: TimeInterval = 6, maxRetriesPerBatch: Int = 20,
                maxRetryCacheSize: Int = 5000000, connectionRetryDuration: TimeInterval = 3) {
        
        self.maxConnectionRetries = maxConnectionRetries
        self.maxConnectionRetryInterval = maxConnectionRetryInterval
        self.maxRetryIntervalPostPrematureDisconnection = maxRetryIntervalPostPrematureDisconnection
        self.maxRetriesPostPrematureDisconnection = maxRetriesPostPrematureDisconnection
        self.maxPingInterval = maxPingInterval
        self.priorities = priorities
        self.flushOnBackground = flushOnBackground
        self.connectionTerminationTimerWaitTime = connectionTerminationTimerWaitTime
        self.maxRequestAckTimeout = maxRequestAckTimeout
        self.maxRetriesPerBatch = maxRetriesPerBatch
        self.maxRetryCacheSize = maxRetryCacheSize
        self.connectionRetryDuration = connectionRetryDuration
    }
}

/// This struct will hold the priorities defined in the ClickstreamConstraints.
public struct Priority {
    private(set) var priority: Int = 0
    private(set) var identifier: PriorityType = "realTime"
    private(set) var maxBatchSize: Double? = 50000
    private(set) var maxTimeBetweenTwoBatches: TimeInterval? = 10
    private(set) var maxCacheSize: Double? = 5000000
    
    public init(priority: Int = 0, identifier: PriorityType = "realTime", maxBatchSize: Double = 50000,
                maxTimeBetweenTwoBatches: TimeInterval = 10, maxCacheSize: Double = 5000000) {
        self.priority = priority
        self.identifier = identifier
        self.maxBatchSize = maxBatchSize
        self.maxTimeBetweenTwoBatches = maxTimeBetweenTwoBatches
        self.maxCacheSize = maxCacheSize
    }
}

public typealias PriorityType = String
