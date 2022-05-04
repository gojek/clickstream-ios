//
//  PerformanceBatchEvent.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 09/09/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

/// This struct is used for aggregating performance events according to bucket type and send it to CleverTap
struct PerformanceBatchEvent {
    var eventName: ClickstreamDebugConstants.Performance.Events
    var bucketType: ClickstreamDebugConstants.Performance.BucketType
    var performanceEvents: [PerformanceEvent]
    
    init(bucketType: ClickstreamDebugConstants.Performance.BucketType, performanceEvents: [PerformanceEvent]) {
        self.eventName = performanceEvents[0].eventName
        self.bucketType = bucketType
        self.performanceEvents = performanceEvents
    }
    
    /// Creates key-value dictionary and send it to CleverTap via Host app
    func notify () {
        var properties: [String: Any] = [ClickstreamDebugConstants.bucketType: bucketType.description]
        
        if let sessionID = Tracker.sharedInstance?.commonProperties?.session.sessionId {
            properties[ClickstreamDebugConstants.clickstream_sessionId] = sessionID
        }
        
        let eventGUIDS = performanceEvents.compactMap { $0.eventGUID }
        if !eventGUIDS.isEmpty {
            let eventGUIDsString = "\(eventGUIDS.joined(separator: ", "))"
            properties[ClickstreamDebugConstants.clickstream_event_guid_list] = eventGUIDsString
        }
        
        let eventBatchGUIDS = performanceEvents.compactMap { $0.eventBatchGUID }
        if !eventBatchGUIDS.isEmpty {
            let eventBatchGUIDSString = "\(eventBatchGUIDS.joined(separator: ", "))"
            properties[ClickstreamDebugConstants.clickstream_event_batch_guid_list] = eventBatchGUIDSString
        }
        
        let dict: [String: Any] = [ClickstreamDebugConstants.eventName: eventName.rawValue,
                                   ClickstreamDebugConstants.eventProperties: properties]
        NotificationCenter.default.post(name: ClickstreamDebugConstants.DebugEventsNotification, object: dict)
    }
}
