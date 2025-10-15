//
//  ClickstreamCourierConnectConfig.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 10/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

public struct ClickstreamCourierConnectConfig: Decodable {
    public let baseURL: String
    public let authURLPath: String
    public let tokenExpiryMins: TimeInterval
    public let pingIntervalMs: TimeInterval
    public let isCleanSessionEnabled: Bool
    public let isTokenCacheExpiryEnabled: Bool
    public let alpn: [String]

    enum CodingKeys: String, CodingKey {
        case baseURL = "base_url"
        case authURLPath = "auth_url_path"
        case tokenExpiryMins = "token_expiry_mins"
        case pingIntervalMs = "ping_interval_ms"
        case isCleanSessionEnabled = "clean_session_enabled"
        case isTokenCacheExpiryEnabled = "token_expiry_cache_enabled"
        case alpn
    }

    public init(
        baseURL: String = "https://integration-api.gojekapi.com",
        authURLPath: String = "/courier/v1/token",
        tokenExpiryMins: TimeInterval = 36.0,
        pingIntervalMs: TimeInterval = 240.0,
        isCleanSessionEnabled: Bool = false,
        isTokenCacheExpiryEnabled: Bool = false,
        alpn: [String] = []
    ) {
        self.baseURL = baseURL
        self.authURLPath = authURLPath
        self.tokenExpiryMins = tokenExpiryMins
        self.pingIntervalMs = pingIntervalMs
        self.isCleanSessionEnabled = isCleanSessionEnabled
        self.isTokenCacheExpiryEnabled = isTokenCacheExpiryEnabled
        self.alpn = alpn
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let baseURLString = try? container.decodeIfPresent(String.self, forKey: .baseURL), !baseURLString.isEmpty else {
            throw DecodingError.valueNotFound(String.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Base URL is required"))
        }
        
        guard let authPath = try? container.decodeIfPresent(String.self, forKey: .authURLPath), !authPath.isEmpty else {
            throw DecodingError.valueNotFound(String.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Auth URL path is required"))
        }

        baseURL = baseURLString
        authURLPath = authPath
        tokenExpiryMins = container.decodeTimeIntervalIfPresent(forKey: .tokenExpiryMins) ?? 36.0
        pingIntervalMs = container.decodeTimeIntervalIfPresent(forKey: .pingIntervalMs) ?? 240.0
        isCleanSessionEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .isCleanSessionEnabled)) ?? false
        isTokenCacheExpiryEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .isTokenCacheExpiryEnabled)) ?? false
        alpn = (try? container.decodeIfPresent([String].self, forKey: .alpn)) ?? []
    }

}
