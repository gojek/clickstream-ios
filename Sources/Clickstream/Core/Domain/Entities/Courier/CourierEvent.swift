//
//  CourierStorableEvent.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 13/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf
import GRDB

struct CourierEvent: EventDatabasePersistable {
    var guid: String
    var timestamp: Date
    var type: PriorityType
    var eventProtoData: Data
    var expiryTime: Date
    
    private enum CodingKeys: String, CodingKey {
        case guid, timestamp, type, eventProtoData, expiryTime
    }
    
    enum Columns {
        static let type = Column(CodingKeys.type)
        static let expiryTime = Column(CodingKeys.expiryTime)
    }
}

// MARK: - DatabasePersistable
// Every implementation must have its own table name & table migration handler
extension CourierEvent {

    static var tableName: String {
        return "courierEvent"
    }
        
    static var tableDefinition: (TableDefinition) -> Void {
        return { t in
            t.primaryKey(["guid"])
            t.column("guid")
            t.column("timestamp", .datetime).notNull()
            t.column("type", .integer).notNull()
            t.column("eventProtoData", .blob)
            // Setting the default value of ttl to 6 months from now the existing entries on DB will have 6 months to live
            t.column("expiryTime", .datetime).notNull().defaults(to: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date())
        }
    }

    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? {
        // Setting the default value of ttl to 6 months from now the existing entries on DB will have 6 months to live
        let time_to_live: (TableAlteration) -> Void = { t in
            t.add(column: "expiryTime", .double).notNull().defaults(to: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date())
        }
        
        return [("adds_ttl_to_courier_event_table", time_to_live)
        ]
    }
}

extension CourierEvent {
    static func initialise(from event: Event) -> Self {
        CourierEvent(guid: event.guid,
                     timestamp: event.timestamp,
                     type: event.type,
                     eventProtoData: event.eventProtoData, expiryTime: Date())
    }
}

// MARK: - TTLPersistable
/// `CourierEvent` carries an explicit `ttl` column, so it opts into TTL-aware
/// persistence queries by exposing that column to the database layer.
extension CourierEvent: TTLPersistable {
    static var ttlColumn: Column { Columns.expiryTime }
}
