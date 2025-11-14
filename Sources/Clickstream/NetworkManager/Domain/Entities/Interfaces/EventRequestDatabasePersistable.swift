//
//  EventRequestDatabasePersistable.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 14/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import GRDB

protocol EventRequestDatabasePersistable: EventRequestPersistable, DatabasePersistable {
    static var tableName: String { get }
    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? { get }
}

// MARK: - DatabasePersistable
// Default implementations
extension EventRequestDatabasePersistable {

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

    static var description: String {
        return tableName
    }
    
    static var primaryKey: String {
        return "guid"
    }
}
