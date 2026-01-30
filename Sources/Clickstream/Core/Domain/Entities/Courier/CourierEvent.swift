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
    var isMirrored: Bool
    var eventProtoData: Data
    
    private enum CodingKeys: String, CodingKey {
        case guid, timestamp, type, isMirrored, eventProtoData
    }
    
    enum Columns {
        static let type = Column(CodingKeys.type)
    }
}

// MARK: - DatabasePersistable
// Every implementation must have its own table name & table migration handler
extension CourierEvent {

    static var tableName: String {
        return "courierEvent"
    }

    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? {
        return nil
    }
}

extension CourierEvent {
    static func initialise(from event: Event) -> Self {
        CourierEvent(guid: event.guid,
                     timestamp: event.timestamp,
                     type: event.type,
                     isMirrored: event.isMirrored,
                     eventProtoData: event.eventProtoData)
    }
}
