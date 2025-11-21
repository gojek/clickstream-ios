//
//  ClickstreamCourierHTTPRetryPolicy.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 14/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

public struct ClickstreamCourierHTTPRetryPolicy {
    public let isEnabled: Bool
    public let delayMillis: TimeInterval
    public let maxRetryCount: Int


    public init(isEnabled: Bool = true,
                delayMillis: TimeInterval = 500.0,
                maxRetryCount: Int = 3) {

        self.isEnabled = isEnabled
        self.delayMillis = delayMillis
        self.maxRetryCount = maxRetryCount
    }
}
