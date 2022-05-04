//
//  HealthAnalysisEventBatch.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 26/08/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

struct HealthAnalysisEventBatch: Codable, Equatable {
    private(set) var eventName: ClickstreamDebugConstants.Health.Events
    private(set) var count: Int
    private(set) var timeStamps: String
    private(set) var eventGUIDs: String
    private(set) var eventBatchGUIDs: String
    private(set) var sessionID: String?
    private(set) var reason: String?
    
    init(eventName: ClickstreamDebugConstants.Health.Events,
         count: Int, timeStamps: String,
         eventGUIDs: String,
         eventBatchGUIDs: String,
         reason: String?) {
        self.eventName = eventName
        self.count = count
        self.timeStamps = timeStamps
        self.eventGUIDs = eventGUIDs
        self.eventBatchGUIDs = eventBatchGUIDs
        self.sessionID = Tracker.sharedInstance?.commonProperties?.session.sessionId
        self.reason = reason
    }
}

extension HealthAnalysisEventBatch: Notifiable {
    
    func notify() {
        var properties: [String: Any] = [ClickstreamDebugConstants.clickstream_event_count: count,
                                          ClickstreamDebugConstants.clickstream_timestamp_list: timeStamps]
        
        if let sessionID = sessionID {
            properties[ClickstreamDebugConstants.clickstream_sessionId] = sessionID
        }
        
        if let reason = reason {
            properties[ClickstreamDebugConstants.clickstream_error_reason] = reason
        }
        
        if !eventGUIDs.isEmpty {
             properties[ClickstreamDebugConstants.clickstream_event_guid_list] = eventGUIDs
        }
        
        if !eventBatchGUIDs.isEmpty {
             properties[ClickstreamDebugConstants.clickstream_event_batch_guid_list] = eventBatchGUIDs
        }
        
        let dict: [String: Any] = [ClickstreamDebugConstants.eventName: eventName.rawValue,
                                   ClickstreamDebugConstants.eventProperties: properties]
        NotificationCenter.default.post(name: ClickstreamDebugConstants.DebugEventsNotification, object: dict)
    }
}
