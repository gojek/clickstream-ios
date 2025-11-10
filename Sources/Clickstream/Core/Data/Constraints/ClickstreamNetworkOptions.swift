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

enum ClickstreamNetworkType {
    case websocket, courier
}

public struct ClickstreamNetworkOptions: Codable {
    public let isWebsocketEnabled: Bool
    public let isCourierEnabled: Bool
    public let courierEventTypes: Set<CourierEventIdentifier>
    public let courierHttpFallbackDelayMs: TimeInterval
    public let courierHttpFallbackMaxRetryCount: Int
    public var courierConfig: ClickstreamCourierConfig

    enum CodingKeys: String, CodingKey {
        case isWebsocketEnabled = "websocket_enabled"
        case isCourierEnabled = "courier_enabled"
        case courierEventTypes = "event_types"
        case courierHttpFallbackDelayMs = "http_fallback_delay"
        case courierHttpMaxRetryCount = "http_fallback_max_retry_count"
        case courierConfig = "courier_config"
    }

    public init(isWebsocketEnabled: Bool = true,
                isCourierEnabled: Bool = false,
                courierEventTypes: Set<CourierEventIdentifier> = [],
                httpFallbackDelayMs: TimeInterval = 500.0,
                httpFallbackMaxRetryCount: Int = 3,
                courierConfig: ClickstreamCourierConfig = ClickstreamCourierConfig()) {

        self.isWebsocketEnabled = isWebsocketEnabled
        self.isCourierEnabled = isCourierEnabled
        self.courierEventTypes = courierEventTypes
        self.courierHttpFallbackDelayMs = httpFallbackDelayMs
        self.courierHttpFallbackMaxRetryCount = httpFallbackMaxRetryCount
        self.courierConfig = courierConfig
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let isWebsocketEnabled = try? container.decode(Bool.self, forKey: .isWebsocketEnabled) {
            self.isWebsocketEnabled = isWebsocketEnabled
        } else {
            self.isWebsocketEnabled = true
        }

        if let isCourierEnabled = try? container.decode(Bool.self, forKey: .isCourierEnabled) {
            self.isCourierEnabled = isCourierEnabled
        } else {
            self.isCourierEnabled = false
        }

        if let courierEventTypes = try? container.decodeIfPresent([String].self, forKey: .courierEventTypes) {
            self.courierEventTypes = Set(courierEventTypes)
        } else {
            self.courierEventTypes = []
        }

        if let courierHttpFallbackDelayMs = try? container.decodeIfPresent(Double.self, forKey: .courierHttpFallbackDelayMs) {
            self.courierHttpFallbackDelayMs = TimeInterval(courierHttpFallbackDelayMs)
        } else if let courierHttpFallbackDelayMs = try? container.decodeIfPresent(Int.self, forKey: .courierHttpFallbackDelayMs) {
            self.courierHttpFallbackDelayMs = TimeInterval(courierHttpFallbackDelayMs)
        } else {
            self.courierHttpFallbackDelayMs = 500.0
        }

        if let courierHttpFallbackMaxRetryCount = try? container.decodeIfPresent(Double.self, forKey: .courierHttpMaxRetryCount) {
            self.courierHttpFallbackMaxRetryCount = Int(courierHttpFallbackMaxRetryCount)
        } else if let courierHttpMaxRetryCount = try? container.decodeIfPresent(Int.self, forKey: .courierHttpMaxRetryCount) {
            self.courierHttpFallbackMaxRetryCount = courierHttpMaxRetryCount
        } else {
            self.courierHttpFallbackMaxRetryCount = 3
        }

        if let courierConfig = try? container.decodeIfPresent(ClickstreamCourierConfig.self, forKey: .courierConfig) {
            self.courierConfig = courierConfig
            self.courierConfig.pollingIntervalMs = self.courierHttpFallbackDelayMs
            self.courierConfig.pollingMaxRetryCount = self.courierHttpFallbackMaxRetryCount
        } else {
            self.courierConfig = ClickstreamCourierConfig()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isWebsocketEnabled, forKey: .isWebsocketEnabled)
        try container.encode(isCourierEnabled, forKey: .isCourierEnabled)
        try container.encode(courierEventTypes, forKey: .courierEventTypes)
        try container.encode(courierHttpFallbackDelayMs, forKey: .courierHttpFallbackDelayMs)
        try container.encode(courierHttpFallbackMaxRetryCount, forKey: .courierHttpMaxRetryCount)
    }
}

extension ClickstreamNetworkOptions {

    func getNetworkType(for event: String) -> ClickstreamNetworkType {
        if isWebsocketEnabled && isCourierEnabled && courierEventTypes.contains(event) {
            return .courier
        }
        if isCourierEnabled {
            return .courier
        }
        return .websocket
    }

    func isConfigEnabled() -> Bool {
        // If both flags are `false`, config should be disabled
        if !isWebsocketEnabled && !isCourierEnabled {
            return false
        }
        return true
    }
}
