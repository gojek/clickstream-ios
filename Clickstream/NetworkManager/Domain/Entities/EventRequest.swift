//
//  EventRequest.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 18/08/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf
import GRDB

struct EventRequest: Codable, Equatable {
    
    var guid: String
    var data: Data?
    var timeStamp: Date
    var retriesMade: Int
    var createdTimestamp: Date?
    var eventType: Constants.EventType?
    var isInternal: Bool?
    
    init(guid: String,
         data: Data? = nil) {
        self.guid = guid
        self.data = data
        self.timeStamp = Date()
        self.retriesMade = 0
        self.createdTimestamp = Date()
        self.isInternal = false
        self.eventType = .realTime
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.guid == rhs.guid
    }
    
    mutating func bumpRetriesMade() {
        retriesMade = (retriesMade + 1)
    }
    
    mutating func refreshCachingTimeStamp() {
        self.timeStamp = Date()
    }
    
    mutating func refreshBatchSentTimeStamp() throws {
        if let data = data {
            var requestProto = try Odpf_Raccoon_EventRequest(serializedData: data)
            requestProto.sentTime = Google_Protobuf_Timestamp(date: Date())
            self.data = try requestProto.serializedData()
        }
    }
}

extension EventRequest: DatabasePersistable {
    static var tableDefinition: (TableDefinition) -> Void {
        get {
            return { t in
                t.primaryKey(["guid"])
                t.column("guid")
                t.column("timeStamp", .datetime).notNull()
                t.column("data", .blob)
                t.column("retriesMade", .text).notNull()
                t.column("createdTimestamp", .datetime).notNull()
            }
        }
    }
    
    static var description: String {
        get {
            return "eventRequest"
        }
    }

    static var codableCacheKey: String {
        return Constants.CacheIdentifiers.retry.rawValue
    }
    
    static var primaryKey: String {
        return "guid"
    }
    
    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? {
        
        let addsIsInternal: (TableAlteration) -> Void = { t in
            t.add(column: "isInternal", .boolean)
        }
        
        let addsEventType: (TableAlteration) -> Void = { t in
            t.add(column: "eventType", .text)
        }
        
        return [("addsIsInternalToEventRequest", addsIsInternal), ("addsEventTypeToEventRequest", addsEventType)]
    }
}
