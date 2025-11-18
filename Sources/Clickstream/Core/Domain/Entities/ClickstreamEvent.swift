//
//  ClickstreamEvent.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 06/08/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

public struct ClickstreamEvent {
    
    private(set) var guid: String
    private(set) var timeStamp: Date
    private(set) var message: Message? // Optional CSEventMessage in Message form
    private(set) var eventName: String // Full event name
    private(set) var eventData: Data // Event in serialized data form
    private(set) var csEventName: String?
    private(set) var product: String

    public init(guid: String,
                timeStamp: Date,
                message: Message?,
                eventName: String,
                eventData: Data,
                csEventName: String? = nil,
                product: String = "Undefined PDG") {

        self.guid = guid
        self.timeStamp = timeStamp
        self.message = message
        self.eventName = eventName
        self.eventData = eventData
        self.csEventName = csEventName
        self.product = product
    }
}

public extension ClickstreamEvent {
    var messageName: String {
        get {
            if let message = message {
                return type(of: message).protoMessageName
            } else {
                return ""
            }
        }
    }
}
