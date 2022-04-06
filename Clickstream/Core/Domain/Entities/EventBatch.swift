//
//  EventBatch.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

struct EventBatch: Codable {
    var uuid: String
    var events: [Event] = []
}

extension EventBatch: ProtoConvertible {
    var proto: Odpf_Raccoon_EventRequest {
        let eventBatch = Odpf_Raccoon_EventRequest.with {
            $0.reqGuid = self.uuid
            $0.sentTime = Google_Protobuf_Timestamp(date: Date())
            $0.events = self.events.map { (eventData) -> Odpf_Raccoon_Event in
                do {
                    return try Odpf_Raccoon_Event(serializedData: eventData.eventProtoData)
                } catch {
                    print("Cannot create CSEventMessage",.critical) // should never happen. handling it gracefully.
                }
                return Odpf_Raccoon_Event()
            }
        }
        return eventBatch
    }
}
