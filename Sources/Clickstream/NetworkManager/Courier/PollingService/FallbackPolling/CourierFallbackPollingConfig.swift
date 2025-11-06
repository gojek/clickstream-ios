//
//  CourierFallbackConfig.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 05/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

struct CourierFallbackPollingConfig: FallbackToPollingConfig {
    
    public let pollingInterval: TimeInterval

    public init(pollingInterval: TimeInterval) {
        self.pollingInterval = pollingInterval
    }
}
