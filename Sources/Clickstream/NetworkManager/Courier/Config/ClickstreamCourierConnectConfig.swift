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
    public let authURLQueries: String?
    public let enableAuthenticationTimeout: Bool
    public let authenticationTimeoutInterval: TimeInterval
    public let autoReconnectInterval: TimeInterval
    public let maxAutoReconnectInterval: TimeInterval
    public let tokenCachingType: Int
    public let tokenExpiryMins: TimeInterval
    public let isTokenCacheExpiryEnabled: Bool
    public let isConnectUserPropertiesEnabled: Bool
    public let alpn: [String]

    enum CodingKeys: String, CodingKey {
        case baseURL = "base_url"
        case authURLPath = "auth_url_path"
        case authURLQueries = "auth_url_queries"
        case enableAuthenticationTimeout = "enable_authentication_timeout"
        case authenticationTimeoutInterval = "authentication_timeout_interval"
        case autoReconnectInterval = "auto_reconnect_interval"
        case maxAutoReconnectInterval = "max_auto_reconnect_interval"
        case tokenCachingType = "token_caching_type"
        case tokenExpiryMins = "token_expiry_mins"
        case isTokenCacheExpiryEnabled = "token_expiry_cache_enabled"
        case isConnectUserPropertiesEnabled = "is_connect_user_properties_enabled"
        case alpn
    }

    public init(
        baseURL: String = "",
        authURLPath: String = "",
        authURLQueries: String? = nil,
        enableAuthenticationTimeout: Bool = true,
        authenticationTimeoutInterval: TimeInterval = 30,
        autoReconnectInterval: TimeInterval = 5,
        maxAutoReconnectInterval: TimeInterval = 10,
        tokenCachingType: Int = 2,
        tokenExpiryMins: TimeInterval = 360.0,
        isTokenCacheExpiryEnabled: Bool = true,
        isConnectUserPropertiesEnabled: Bool = true,
        alpn: [String] = ["mqtt"]
    ) {
        self.baseURL = baseURL
        self.authURLPath = authURLPath
        self.authURLQueries = authURLQueries
        self.enableAuthenticationTimeout = enableAuthenticationTimeout
        self.authenticationTimeoutInterval = authenticationTimeoutInterval
        self.autoReconnectInterval = autoReconnectInterval
        self.maxAutoReconnectInterval = maxAutoReconnectInterval
        self.tokenCachingType = tokenCachingType
        self.tokenExpiryMins = tokenExpiryMins
        self.isTokenCacheExpiryEnabled = isTokenCacheExpiryEnabled
        self.isConnectUserPropertiesEnabled = isConnectUserPropertiesEnabled
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
        authURLQueries = (try? container.decodeIfPresent(String.self, forKey: .authURLQueries))
        enableAuthenticationTimeout = (try? container.decodeIfPresent(Bool.self, forKey: .enableAuthenticationTimeout)) ?? false
        authenticationTimeoutInterval = container.decodeTimeIntervalIfPresent(forKey: .authenticationTimeoutInterval) ?? 30.0
        autoReconnectInterval = container.decodeTimeIntervalIfPresent(forKey: .autoReconnectInterval) ?? 1.0
        maxAutoReconnectInterval = container.decodeTimeIntervalIfPresent(forKey: .maxAutoReconnectInterval) ?? 30.0
        tokenCachingType = (try? container.decodeIfPresent(Int.self, forKey: .tokenCachingType)) ?? 2
        tokenExpiryMins = container.decodeTimeIntervalIfPresent(forKey: .tokenExpiryMins) ?? 360.0
        isTokenCacheExpiryEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .isTokenCacheExpiryEnabled)) ?? false
        isConnectUserPropertiesEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .isConnectUserPropertiesEnabled)) ?? false
        alpn = (try? container.decodeIfPresent([String].self, forKey: .alpn)) ?? []
    }
}
