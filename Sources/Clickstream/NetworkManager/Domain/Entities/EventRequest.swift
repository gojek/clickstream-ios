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

struct EventRequest: EventRequestDatabasePersistable {

    let guid: String
    var data: Data?
    var timeStamp: Date
    var retriesMade: Int
    var createdTimestamp: Date?
    var eventType: Constants.EventType?
    var isInternal: Bool?
    var eventCount: Int
    
    init(guid: String, data: Data? = nil) {
        self.guid = guid
        self.data = data
        self.timeStamp = Date()
        self.retriesMade = 0
        self.createdTimestamp = Date()
        self.isInternal = false
        self.eventType = .realTime
        self.eventCount = 0
    }
}

// MARK: - DatabasePersistable
// Every implementation must have its own table name, schema, and migration handler
extension EventRequest {

    static var tableName: String {
        return "eventRequest"
    }

    static var tableDefinition: (TableDefinition) -> Void {
        return { t in
            t.primaryKey(["guid"])
            t.column("guid")
            t.column("timeStamp", .datetime).notNull()
            t.column("data", .blob)
            t.column("retriesMade", .text).notNull()
            t.column("createdTimestamp", .datetime).notNull()
            t.column("eventCount", .integer).notNull()
        }
    }

    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? {
        
        let addsIsInternal: (TableAlteration) -> Void = { t in
            t.add(column: "isInternal", .boolean)
        }
        
        let addsEventType: (TableAlteration) -> Void = { t in
            t.add(column: "eventType", .text)
        }
        
        let addsEventCount: (TableAlteration) -> Void = { t in
            t.add(column: "eventCount", .integer).notNull().defaults(to: 0)
        }
        
        return [("addsIsInternalToEventRequest", addsIsInternal), 
                ("addsEventTypeToEventRequest", addsEventType),
                ("addsEventCountToEventRequest", addsEventCount)
        ]
    }
}
