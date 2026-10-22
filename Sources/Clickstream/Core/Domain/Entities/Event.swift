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

struct Event: EventDatabasePersistable {
    var guid: String
    var timestamp: Date
    var type: PriorityType
    var eventProtoData: Data
    
    private enum CodingKeys: String, CodingKey {
        case guid, timestamp, type, eventProtoData
    }
    
    enum Columns {
        static let type = Column(CodingKeys.type)
    }
}

// MARK: - DatabasePersistable
// Every implementation must have its own table name & table migration handler
extension Event {

    static var tableName: String {
        return "event"
    }

    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? {
        return nil
    }
}
