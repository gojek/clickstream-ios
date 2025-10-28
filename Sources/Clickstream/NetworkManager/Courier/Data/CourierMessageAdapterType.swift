//
//  CourierMessageAdapterType.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 13/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierMQTT

public enum CourierMessageAdapterType: String, Decodable {
    case json, data, text, plist
    
    static func mapped(from type: CourierMessageAdapterType) -> MessageAdapter? {
        guard let config = CourierMessageAdapterType(rawValue: type.rawValue) else { return nil }

        switch config {
        case .json:
            return JSONMessageAdapter()
        case .data:
            return DataMessageAdapter()
        case .text:
            return TextMessageAdapter()
        case .plist:
            return PlistMessageAdapter()
        }
    }
}

