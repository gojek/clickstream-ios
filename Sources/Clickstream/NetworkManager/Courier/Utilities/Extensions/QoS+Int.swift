//
//  QoS+Int.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 13/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierCore

extension QoS {
    init?(value: Int) {
        switch value {
        case 0: self = .zero
        case 1: self = .one
        case 2: self = .two
        case 3: self = .oneWithoutPersistenceAndNoRetry
        case 4: self = .oneWithoutPersistenceAndRetry
        default: return nil
        }
    }
}
