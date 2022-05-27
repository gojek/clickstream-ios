//
//  HealthAnalysisEvent.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 26/08/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import GRDB

struct HealthAnalysisEvent: Codable, Equatable, AnalysisEvent {
    
    private(set) var guid: String
    private(set) var eventName: TrackerConstant.Events
    private(set) var eventType: TrackerConstant.EventType
    private(set) var timestamp: String
    private(set) var reason: String?
    private(set) var eventGUID: String?
    private(set) var eventBatchGUID: String?
    private(set) var events: String?
    private(set) var sessionID: String?
    // Needs to be kept optional, as the old SQL schema will not have this field.
    private(set) var trackedVia: String?
    
    init?(eventName: TrackerConstant.Events,
          events: String? = nil,
          eventGUID: String? = nil,
          eventBatchGUID: String? = nil,
          reason: String? = nil) {
        
        // Don't initialize if debugMode is off
        guard Tracker.debugMode  else {
            return nil
        }
        
        self.eventName = eventName
        let currentTimestamp = Date()
        self.timestamp = "\(currentTimestamp)"
        self.reason = reason
        self.eventGUID = eventGUID
        self.eventBatchGUID = eventBatchGUID
        self.eventType = TrackerConstant.InstantEvents.contains(eventName) ? .instant : .aggregate
        self.events = events
        self.guid = UUID().uuidString
        self.sessionID = Tracker.sharedInstance?.commonProperties?.session.sessionId
        
        self.trackedVia = Tracker.healthTrackingConfigs.trackedVia.rawValue
    }
    
    private enum CodingKeys : String, CodingKey {
        case guid,eventName,eventType,timestamp,reason,eventGUID,eventBatchGUID,events,sessionID,trackedVia
    }
    
    static func == (lhs: HealthAnalysisEvent, rhs: HealthAnalysisEvent) -> Bool {
        lhs.guid == rhs.guid
    }
    
    enum Columns {
        static let trackedVia = Column(CodingKeys.trackedVia)
    }
}

extension HealthAnalysisEvent: Notifiable {
    
    func notify() {
        var properties: [String: Any] = [TrackerConstant.clickstream_timestamp: timestamp]
        
        if let eventGUID = eventGUID {
            properties[TrackerConstant.clickstream_event_guid] = eventGUID
        }
        
        if let eventBatchGUID = eventBatchGUID {
            properties[TrackerConstant.clickstream_event_batch_guid] = eventBatchGUID
        }
        
        if let events = events {
            properties[TrackerConstant.clickstream_event_guid_list] = events
        }
        
        if let sessionID = sessionID {
            properties[TrackerConstant.clickstream_sessionId] = sessionID
        }
        
        if let reason = reason {
            properties[TrackerConstant.clickstream_error_reason] = reason
        }
        
        let dict: [String : Any] = [TrackerConstant.eventName: eventName.rawValue,
                                    TrackerConstant.eventProperties: properties]
        NotificationCenter.default.post(name: TrackerConstant.DebugEventsNotification, object: dict)
    }
}

extension HealthAnalysisEvent: DatabasePersistable {
    static var tableDefinition: (TableDefinition) -> Void {
        get {
            return { t in
                t.primaryKey(["guid"])
                t.column("guid")
                t.column("eventName", .integer)
                t.column("eventType", .integer)
                t.column("timestamp", .text)
                t.column("reason", .text)
                t.column("eventGUID", .text)
                t.column("eventBatchGUID", .text)
                t.column("events", .text)
                t.column("sessionID", .text)
            }
        }
    }
    
    static var description: String {
        get {
            return "healthAnalysisEvent"
        }
    }
    
    static var codableCacheKey: String {
        return Constants.CacheIdentifiers.healthAnalytics.rawValue
    }
    
    static var primaryKey: String {
        return "guid"
    }
    
    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? {

        let addsTrackedVia: (TableAlteration) -> Void = { t in
            t.add(column: "trackedVia", .text)
        }
        
        return [("addsTrackedViaToHealthEvent", addsTrackedVia)]
    }
}