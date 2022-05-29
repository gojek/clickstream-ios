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
    private(set) var eventGUIDs: [String]
    private(set) var eventBatchGUIDs: [String]
    private(set) var sessionID: String?
    private(set) var reason: String?
    
    init(eventName: TrackerConstant.Events,
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
