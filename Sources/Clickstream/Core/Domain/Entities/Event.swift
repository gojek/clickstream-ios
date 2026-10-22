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

    init(guid: String, timestamp: Date, type: PriorityType, eventProtoData: Data) {
        self.guid = guid
        self.timestamp = timestamp
        self.type = type
        self.eventProtoData = eventProtoData
    }
    
    private enum CodingKeys: String, CodingKey {
        case guid, timestamp, type, eventProtoData
    }
    
    enum Columns {
        static let type = Column(CodingKeys.type)
    }
}

extension Event {

    /// Wraps the serialized bytes of a proto message into an `Event` as expected by Raccoon.
    /// - Parameters:
    ///   - guid: GUID of the event.
    ///   - messageBytes: Serialized proto message.
    ///   - messageName: Full proto name of the message, like `type(of: message).protoMessageName`.
    ///   - type: Type of the event.
    init?(guid: String, messageBytes: Data, messageName: String, type: PriorityType) {
        do {
            let eventProto = try Odpf_Raccoon_Event.with {
                $0.eventBytes = messageBytes
                if let typeOfEvent = messageName.components(separatedBy: ".").last {
                    $0.type = typeOfEvent.lowercased()
                }
            }
            self.init(guid: guid,
                      timestamp: Date(),
                      type: type,
                      eventProtoData: try eventProto.serializedData())
        } catch {
            return nil
        }
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
