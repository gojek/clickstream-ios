//
//  EventBatchPersistable.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 14/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol EventBatchPersistable: Codable, ProtoConvertible {
    associatedtype EventType: EventPersistable

    var uuid: String { get }
    var events: [EventType] { get }
}

extension EventBatchPersistable {
    var proto: Odpf_Raccoon_EventRequest {
        let eventBatch = Odpf_Raccoon_EventRequest.with {
            $0.reqGuid = self.uuid
            $0.sentTime = Google_Protobuf_Timestamp(date: Date())
            $0.events = self.events.map { eventData -> Odpf_Raccoon_Event in
                do {
                    return try Odpf_Raccoon_Event(serializedBytes: eventData.eventProtoData)
                } catch {
                    print("Cannot create CSEventMessage", .critical)
                }
                return Odpf_Raccoon_Event()
            }
        }
        return eventBatch
    }
}
