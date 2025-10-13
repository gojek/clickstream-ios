//
//  Decoding+TimeInterval.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 13/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
    func decodeTimeIntervalIfPresent(forKey key: Key) -> TimeInterval? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        } else if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        } else if let stringValue = try? decodeIfPresent(String.self, forKey: key), let doubleValue = Double(stringValue) {
            return doubleValue
        }

        return nil
    }
}
