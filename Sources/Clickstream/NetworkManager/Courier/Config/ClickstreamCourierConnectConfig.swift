//
//  ClickstreamCourierConnectConfig.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 10/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

public struct ClickstreamCourierConnectConfig: Decodable {
    public let authURL: String
    public let tokenExpiryMins: TimeInterval
    public let pingIntervalMs: TimeInterval
    public let isCleanSessionEnabled: Bool
    public let alpn: [String]

    enum CodingKeys: String, CodingKey {
        case authURL = "auth_url"
        case tokenExpiryMins = "token_expiry_mins"
        case pingIntervalMs = "ping_interval_ms"
        case isCleanSessionEnabled = "clean_session_enabled"
        case alpn
    }

    public init(
        authURL: String = "",
        tokenExpiryMins: TimeInterval = 36.0,
        pingIntervalMs: TimeInterval = 240.0,
        isCleanSessionEnabled: Bool = false,
        alpn: [String] = []
    ) {
        self.authURL = authURL
        self.tokenExpiryMins = tokenExpiryMins
        self.pingIntervalMs = pingIntervalMs
        self.isCleanSessionEnabled = isCleanSessionEnabled
        self.alpn = alpn
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let url = try container.decodeIfPresent(String.self, forKey: .authURL), url.isEmpty else {
            fatalError("Courier authentication URL must be provided")
        }

        authURL = url
        tokenExpiryMins = container.decodeTimeIntervalIfPresent(forKey: .tokenExpiryMins) ?? 36.0
        pingIntervalMs = container.decodeTimeIntervalIfPresent(forKey: .pingIntervalMs) ?? 240.0
        isCleanSessionEnabled = try container.decodeIfPresent(Bool.self, forKey: .isCleanSessionEnabled) ?? false
        alpn = try container.decodeIfPresent([String].self, forKey: .alpn) ?? []
    }

}
