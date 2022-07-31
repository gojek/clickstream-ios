//
//  MockConstants.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 02/07/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import Foundation

struct MockConstants {
    
    static let constraints: ClickstreamConstraints = {
        let realTimePriority = Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000, maxTimeBetweenTwoBatches: 10, maxCacheSize: 5000000)
        let standardPriority = Priority(priority: 1, identifier: "standard", maxCacheSize: 1000000)
        return ClickstreamConstraints(maxConnectionRetries: 10, maxConnectionRetryInterval: 30, maxRetryIntervalPostPrematureDisconnection: 30, maxRetriesPostPrematureDisconnection: 10, maxPingInterval: 15, priorities: [realTimePriority, standardPriority], flushOnBackground: true, connectionTerminationTimerWaitTime: 2, maxRequestAckTimeout: 6, maxRetriesPerBatch: 20, maxRetryCacheSize: 5000000, connectionRetryDuration: 3)
    }()
    
    static let eventClassification: ClickstreamEventClassification = {
        let testRealtimeEvent = ClickstreamEventClassification.EventClassifier(identifier: "ClickstreamTestRealtime", eventNames: ["AdCardEvent"])
        let testStandardEvent = ClickstreamEventClassification.EventClassifier(identifier: "ClickstreamTestStandard", eventNames: ["GoChat", "GoPay"])
        
        return ClickstreamEventClassification(eventTypes: [testRealtimeEvent, testStandardEvent])
    }()
}
