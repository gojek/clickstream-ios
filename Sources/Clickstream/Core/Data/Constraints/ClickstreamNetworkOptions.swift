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
    public let networkChannelSplitEnabled: Bool
    public let courierEventTypes: Set<CourierEventIdentifier>
    public let courierRetryPolicy: ClickstreamCourierRetryPolicy
    public let courierRetryHTTPPolicy: ClickstreamCourierHTTPRetryPolicy
    public let courierConfig: ClickstreamCourierClientConfig
    public let clickstreamConstraints: ClickstreamCourierConstraints

    public init(isWebsocketEnabled: Bool = true,
                isCourierEnabled: Bool = false,
                networkChannelSplitEnabled: Bool = false,
                courierEventTypes: Set<CourierEventIdentifier> = [],
                courierRetryPolicy: ClickstreamCourierRetryPolicy = .init(),
                courierRetryHTTPPolicy: ClickstreamCourierHTTPRetryPolicy = .init(),
                courierConfig: ClickstreamCourierClientConfig = .init(),
                clickstreamConstraints: ClickstreamCourierConstraints = .init()) {

        self.isWebsocketEnabled = isWebsocketEnabled
        self.isCourierEnabled = isCourierEnabled
        self.networkChannelSplitEnabled = networkChannelSplitEnabled
        self.courierEventTypes = courierEventTypes
        self.courierRetryPolicy = courierRetryPolicy
        self.courierRetryHTTPPolicy = courierRetryHTTPPolicy
        self.courierConfig = courierConfig
        self.clickstreamConstraints = clickstreamConstraints
    }
}
