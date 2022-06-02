//
//  HealthAnalysisEventBatch.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 26/08/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

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
        let healthDTO = HealthTrackerDTO()
        healthDTO.eventName = self.eventName.rawValue
        healthDTO.sessionID = sessionID
        healthDTO.failureReason = reason
        healthDTO.eventGUIDs = self.eventGUIDs
        healthDTO.eventBatchGUIDs = self.eventBatchGUIDs
        
        healthDTO.eventCount = healthDTO.eventGUIDs?.count
        
        NotificationCenter.default.post(name: TrackerConstant.DebugEventsNotification, object: healthDTO)
    }
}
