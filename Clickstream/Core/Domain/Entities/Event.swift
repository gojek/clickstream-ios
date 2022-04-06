//
//  Event.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 22/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf
import GRDB

struct Event: Codable, Comparable, Hashable {
    
    var guid: String
    var timestamp: Date
    var type: PriorityType
    var eventProtoData: Data // CSEventMessage in serialized data form
    
    private enum CodingKeys : String, CodingKey {
        case guid, timestamp, type, eventProtoData
    }
    
    static func < (lhs: Event, rhs: Event) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
    
    enum Columns {
        static let type = Column(CodingKeys.type)
    }
}

extension Event: DatabasePersistable {
    
    static var tableDefinition: (TableDefinition) -> Void {
        get {
            return { t in
                t.primaryKey(["guid"])
                t.column("guid")
                t.column("timestamp", .datetime).notNull()
                t.column("type", .integer).notNull()
                t.column("eventProtoData", .blob)
            }
        }
    }
    
    static var description: String {
        get {
            return "event"
        }
    }
    
    static var codableCacheKey: String {
        return "realTime"
    }
    
    static var primaryKey: String {
        return "guid"
    }
    
    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? {
        return nil
    }
}
