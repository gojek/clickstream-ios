//
//  CourierConnectTimeoutPolicy.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 13/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierMQTT

public struct CourierConnectTimeoutPolicy: IConnectTimeoutPolicy, Decodable {
    public var isEnabled: Bool
    public var timerInterval: TimeInterval
    public var timeout: TimeInterval

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case timerInterval = "timer_interval"
        case timeout
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        timerInterval = container.decodeTimeIntervalIfPresent(forKey: .timerInterval) ?? 16.0
        timeout = container.decodeTimeIntervalIfPresent(forKey: .timeout) ?? 10.0
    }
}
