//
//  EventBatch.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

struct EventBatch: EventBatchPersistable {
    typealias EventType = Event
    
    var uuid: String
    var events: [Event] = []
}
