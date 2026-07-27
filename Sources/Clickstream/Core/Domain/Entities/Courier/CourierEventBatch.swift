//
//  CourierEventBatch.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 13/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

struct CourierEventBatch: EventBatchPersistable {
    typealias EventType = CourierEvent
    
    var uuid: String
    var events: [CourierEvent] = []

    /// Optional MQTT QoS level for this batch, resolved from the event classification.
    /// When `nil`, the courier handler falls back to its configured default QoS.
    var qos: Int?
}
