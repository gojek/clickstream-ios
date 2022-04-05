//
//  MockConstants.swift
//  ClickStreamTests
//
//  Created by Abhijeet Mallick on 02/07/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

struct MockConstants {
    
    static let constraints: ClickStreamConstraints = {
        let realTimePriority = Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000, maxTimeBetweenTwoBatches: 10, maxCacheSize: 5000000)
        let standardPriority = Priority(priority: 1, identifier: "standard", maxCacheSize: 1000000)
        return ClickStreamConstraints(maxConnectionRetries: 10, maxConnectionRetryInterval: 30, maxRetryIntervalPostPrematureDisconnection: 30, maxRetriesPostPrematureDisconnection: 10, maxPingInterval: 15, priorities: [realTimePriority, standardPriority], flushOnBackground: true, connectionTerminationTimerWaitTime: 2, maxRequestAckTimeout: 6, maxRetriesPerBatch: 20, maxRetryCacheSize: 5000000, connectionRetryDuration: 3)
    }()
    
    static let eventClassification: ClickStreamEventClassification = {
        let testRealtimeEvent = ClickStreamEventClassification.EventClassifier(identifier: "ClickStreamTestRealtime", eventNames: ["gojek.clickstream.products.events.AdCardEvent"])
        let testStandardEvent = ClickStreamEventClassification.EventClassifier(identifier: "ClickStreamTestStandard", eventNames: ["GoChat", "GoPay"])
        
        return ClickStreamEventClassification(eventTypes: [testRealtimeEvent, testStandardEvent])
    }()
}
