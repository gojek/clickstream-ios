//
//  PublishFallbackPolicy.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 05/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierCore

final class PublishFallbackPolicy: BaseFallbackPolicy {

    init(delay: TimeInterval) {
        super.init(delay: delay)
    }

    public override func onEvent(_ event: CourierEvent) {
        switch event.type {
        case .messageSend(let topic, let qos, let size):
            schedule()

        case .messageSendSuccess(let topic, let qos, let size):
            cancel()

        case .messageSendFailure(let topic, let qos, let error, let size):
            cancel()

        default:
            return
        }
    }
}
