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
    
    public init(guid: String, timeStamp: Date, message: Message?, eventName: String, eventData: Data) {
        self.guid = guid
        self.timeStamp = timeStamp
        self.message = message
        self.eventName = eventName
        self.eventData = eventData
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
