//
//  CourierIdleActivityTimeoutPolicy.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 13/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierMQTT

public struct CourierIdleActivityTimeoutPolicy: IdleActivityTimeoutPolicyProtocol, Decodable {
    public var isEnabled: Bool
    public var timerInterval: TimeInterval
    public var inactivityTimeout: TimeInterval
    public var readTimeout: TimeInterval

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case timerInterval = "timer_interval"
        case inactivityTimeout = "inactivity_timeout"
        case readTimeout = "read_timeout"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        timerInterval = container.decodeTimeIntervalIfPresent(forKey: .timerInterval) ?? 12.0
        inactivityTimeout = container.decodeTimeIntervalIfPresent(forKey: .inactivityTimeout) ?? 10.0
        readTimeout = container.decodeTimeIntervalIfPresent(forKey: .readTimeout) ?? 40.0
    }
}
