//
//  HealthAnalysisEventBatch.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 26/08/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

struct HealthAnalysisEventBatch: Codable, Equatable {
    private(set) var eventName: TrackerConstant.Events
    private(set) var count: Int
    private(set) var timeStamps: String
    private(set) var eventGUIDs: String
    private(set) var eventBatchGUIDs: String
    private(set) var sessionID: String?
    private(set) var reason: String?
    
    init(eventName: TrackerConstant.Events,
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
