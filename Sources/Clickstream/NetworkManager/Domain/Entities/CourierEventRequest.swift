//
//  CourierEventRequest.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 14/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import GRDB

struct CourierEventRequest: EventRequestDatabasePersistable {

    let guid: String
    var data: Data?
    var timeStamp: Date
    var retriesMade: Int
    var createdTimestamp: Date?
    var eventType: Constants.EventType?
    var isInternal: Bool?
    var eventCount: Int
    var retryCount: Int
    
    init(guid: String, data: Data? = nil) {
        self.guid = guid
        self.data = data
        self.timeStamp = Date()
        self.retriesMade = 0
        self.createdTimestamp = Date()
        self.isInternal = false
        self.eventType = .realTime
        self.eventCount = 0
        self.retryCount = 0
    }
}

// MARK: - DatabasePersistable
// Every implementation must have its own table name, schema, and migration handler
extension CourierEventRequest {

    static var tableName: String {
        return "courierEventRequest"
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
            t.column("retryCount", .integer).notNull()
        }
    }

    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? {
        return nil
    }
}
