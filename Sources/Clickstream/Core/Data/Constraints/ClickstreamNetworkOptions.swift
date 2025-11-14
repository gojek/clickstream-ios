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

public struct ClickstreamNetworkOptions: Decodable {
    public let isWebsocketEnabled: Bool
    public let isCourierEnabled: Bool
    public let courierEventTypes: Set<CourierEventIdentifier>
    public var courierConfig: ClickstreamCourierConfig

    enum CodingKeys: String, CodingKey {
        case isWebsocketEnabled = "websocket_enabled"
        case isCourierEnabled = "courier_enabled"
        case courierEventTypes = "event_types"
        case courierConfig = "courier_config"
    }

    public init(isWebsocketEnabled: Bool = true,
                isCourierEnabled: Bool = false,
                courierEventTypes: Set<CourierEventIdentifier> = [],
                courierConfig: ClickstreamCourierConfig = ClickstreamCourierConfig()) {

        self.isWebsocketEnabled = isWebsocketEnabled
        self.isCourierEnabled = isCourierEnabled
        self.courierEventTypes = courierEventTypes
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

        if let courierConfig = try? container.decodeIfPresent(ClickstreamCourierConfig.self, forKey: .courierConfig) {
            self.courierConfig = courierConfig
        } else {
            self.courierConfig = ClickstreamCourierConfig()
        }
    }
}

extension ClickstreamNetworkOptions {

    var isCourierExperimentFlowEnabled: Bool {
        // If both flags are `false`, config should be disabled
        if !isWebsocketEnabled && !isCourierEnabled {
            return false
        }
        return true
    }
}
