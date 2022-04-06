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
    private(set) var message: Message // CSEventMessage in serialized data form
    
    public init(guid: String, timeStamp: Date, message: Message) {
        self.guid = guid
        self.timeStamp = timeStamp
        self.message = message
    }
}
