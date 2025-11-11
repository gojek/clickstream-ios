//
//  ClickstreamCourierFallbackPolicy.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 11/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

public struct ClickstreamCourierFallbackPolicy {
    public let isEnabled: Bool
    public let delayMillis: TimeInterval
    public let retryDelayMillis: TimeInterval
    public let retryCount: Int

    public init(isEnabled: Bool = true,
                delayMillis: TimeInterval = 500.0,
                retryDelayMillis: TimeInterval = 500.0,
                retryCount: Int = 3) {

        self.isEnabled = isEnabled
        self.delayMillis = delayMillis
        self.retryDelayMillis = retryDelayMillis
        self.retryCount = retryCount
    }
}
