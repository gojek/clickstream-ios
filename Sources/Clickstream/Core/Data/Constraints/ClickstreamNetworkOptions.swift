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
    let isWebsocketEnabled: Bool
    let isCourierEnabled: Bool
    let courierEventTypes: Set<CourierEventIdentifier>
    let courierHttpFallbackDelayMs: TimeInterval
    let courierConfig: ClickstreamCourierConfig

    enum CodingKeys: String, CodingKey {
        case isWebsocketEnabled = "websocket_enabled"
        case isCourierEnabled = "courier_enabled"
        case courierEventTypes = "event_types"
        case courierHttpFallbackDelayMs = "http_fallback_delay"
        case courierConfig = "courier_config"
    }

    public init(isWebsocketEnabled: Bool = true,
                isCourierEnabled: Bool = false,
                courierEventTypes: Set<CourierEventIdentifier> = [],
                httpFallbackDelayMs: TimeInterval = 500.0,
                courierConfig: ClickstreamCourierConfig = ClickstreamCourierConfig()) {

        self.isWebsocketEnabled = isWebsocketEnabled
        self.isCourierEnabled = isCourierEnabled
        self.courierEventTypes = courierEventTypes
        self.courierHttpFallbackDelayMs = httpFallbackDelayMs
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
            self.courierHttpFallbackDelayMs =  TimeInterval(courierHttpFallbackDelayMs)
        } else if let courierHttpFallbackDelayMs = try? container.decodeIfPresent(Int.self, forKey: .courierHttpFallbackDelayMs) {
            self.courierHttpFallbackDelayMs = TimeInterval(courierHttpFallbackDelayMs)
        } else {
            self.courierHttpFallbackDelayMs = 500.0
        }

        if let courierConfig = try? container.decodeIfPresent(ClickstreamCourierConfig.self, forKey: .courierConfig) {
            self.courierConfig = courierConfig
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
    }
}

extension ClickstreamNetworkOptions {

    func getNetworkType(for event: String) -> ClickstreamNetworkType {
        if isCourierEnabled && courierEventTypes.contains(event) {
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
