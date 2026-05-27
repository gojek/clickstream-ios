//
//  CSBinaryEvent.swift
//  Clickstream
//
//  Copyright © 2026 Gojek. All rights reserved.
//

import Foundation

public struct CSBinaryEvent {

    public let guid: String
    public let timestamp: Date
    public let type: String
    public let eventName: String
    public let encodedData: String
    public let product: String?

    public init(type: String,
                encodedData: String,
                product: String? = nil,
                eventName: String? = nil) {
        self.guid = UUID().uuidString
        self.timestamp = Date()
        self.type = type
        self.eventName = eventName ?? type
        self.encodedData = encodedData
        self.product = product
    }
}
