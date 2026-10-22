//
//  HealthAnalysisEventBatch.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 26/08/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

/// Used for tracking health events in aggregated form
struct HealthAnalysisEventBatch: Codable, Equatable {
    
    /// Health event name
    private(set) var eventName: HealthEvents
    
    /// Number of health events being sent
    private(set) var count: Int
    
    /// List of timestamps of client app event
    private(set) var timeStamps: String
    
    /// List of GUIDs of client app event
    private(set) var eventGUIDs: [String]
    
    /// Batch GUID of client app event
    private(set) var eventBatchGUIDs: [String]
    
    /// Client app session ID
    private(set) var sessionID: String?
    
    /// Error reason like socket failure or JSON parsion error
    private(set) var reason: String?
    
    init(eventName: HealthEvents,
         count: Int, timeStamps: String,
         eventGUIDs: [String],
         eventBatchGUIDs: [String],
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
        var properties: [String: Any] = [TrackerConstant.clickstream_event_count: count,
                                         TrackerConstant.clickstream_timestamp_list: timeStamps]
        
        if let sessionID = sessionID {
            properties[TrackerConstant.clickstream_sessionId] = sessionID
        }
        
        if let reason = reason {
            properties[TrackerConstant.clickstream_error_reason] = reason
        }
        
        if !eventGUIDs.isEmpty {
             properties[TrackerConstant.clickstream_event_guid_list] = eventGUIDs
        }
        
        if !eventBatchGUIDs.isEmpty {
             properties[TrackerConstant.clickstream_event_batch_guid_list] = eventBatchGUIDs
        }
        
        let dict: [String: Any] = [TrackerConstant.eventName: eventName.rawValue,
                                   TrackerConstant.eventProperties: properties]
        NotificationCenter.default.post(name: TrackerConstant.DebugEventsNotification, object: dict)
    }
}
