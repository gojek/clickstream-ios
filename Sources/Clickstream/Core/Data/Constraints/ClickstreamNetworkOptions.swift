//
//  ClickstreamNetworkOptions.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 03/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

/// Event type identifier for courier
public typealias CourierEventIdentifier = String

public struct ClickstreamNetworkOptions {

    public let isWebsocketEnabled: Bool
    public let isCourierEnabled: Bool
    public let isCourierPreAuthEnabled: Bool
    public let courierEventTypes: Set<CourierEventIdentifier>
    public let courierExclusiveEventTypes: Set<CourierEventIdentifier>
    public let courierExclusiveEventsEnabled: Bool
    public let courierRetryPolicy: ClickstreamCourierRetryPolicy
    public let courierRetryHTTPPolicy: ClickstreamCourierHTTPRetryPolicy
    public let courierConfig: ClickstreamCourierClientConfig
    public let clickstreamConstraints: ClickstreamCourierConstraints

    public init(isWebsocketEnabled: Bool = true,
                isCourierEnabled: Bool = false,
                isCourierPreAuthEnabled: Bool = false,
                courierEventTypes: Set<CourierEventIdentifier> = [],
                courierExclusiveEventTypes: Set<CourierEventIdentifier> = [],
                courierExclusiveEventsEnabled: Bool = false,
                courierRetryPolicy: ClickstreamCourierRetryPolicy = .init(),
                courierRetryHTTPPolicy: ClickstreamCourierHTTPRetryPolicy = .init(),
                courierConfig: ClickstreamCourierClientConfig = .init(),
                clickstreamConstraints: ClickstreamCourierConstraints = .init()) {

        self.isWebsocketEnabled = isWebsocketEnabled
        self.isCourierEnabled = isCourierEnabled
        self.isCourierPreAuthEnabled = isCourierPreAuthEnabled
        self.courierEventTypes = courierEventTypes
        self.courierExclusiveEventTypes = courierExclusiveEventTypes
        self.courierExclusiveEventsEnabled = courierExclusiveEventsEnabled
        self.courierRetryPolicy = courierRetryPolicy
        self.courierRetryHTTPPolicy = courierRetryHTTPPolicy
        self.courierConfig = courierConfig
        self.clickstreamConstraints = clickstreamConstraints
    }
}
