//
//  EventDatabasePersistable.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 14/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import GRDB

protocol EventDatabasePersistable: EventPersistable, DatabasePersistable {
    static var tableName: String { get }
    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? { get }
}

// MARK: - DatabasePersistable
// Default implementations
extension EventDatabasePersistable {

    static var tableDefinition: (TableDefinition) -> Void {
        return { t in
            t.primaryKey(["guid"])
            t.column("guid")
            t.column("timestamp", .datetime).notNull()
            t.column("type", .integer).notNull()
            t.column("eventProtoData", .blob)
            t.column("isMirrored", .boolean).defaults(to: false)
        }
    }
    
    static var primaryKey: String {
        return "guid"
    }

    static var description: String {
        return tableName
    }
}
