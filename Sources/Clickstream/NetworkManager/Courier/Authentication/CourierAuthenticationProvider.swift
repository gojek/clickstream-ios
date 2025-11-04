//
//  CourierAuthenticationProvider.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 10/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import CourierCore
import Foundation
import UIKit

enum CourierApplicationState: String {
    case background, foreground
}

enum CourierConnectCacheType: Int {
    case noop, inMemory, disk
}

final class CourierAuthenticationProvider: IConnectionServiceProvider {

    private let cachingType: CourierConnectCacheType
    private let userDefaults: UserDefaults
    private let userDefaultsKey: String

    private let config: ClickstreamCourierConfig

    private let isConnectUserPropertiesEnabled: Bool
    private let networkTypeProvider: NetworkType
    private let applicationState: CourierApplicationState

    private var _cachedAuthResponse: Atomic<CourierConnect?>
    private(set) var cachedAuthResponse: CourierConnect? {
        get { _cachedAuthResponse.value }
        set {
            _cachedAuthResponse.mutate { $0 = newValue }

            guard cachingType == .disk else { return }
            if let newValue = newValue, let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: userDefaultsKey)
            } else {
                userDefaults.removeObject(forKey: userDefaultsKey)
            }
        }
    }

    var clientId: String {
        var id = "\(userCredentials.userIdentifier)"

        if let extraId = userCredentials.extraIdentifier, !extraId.isEmpty {
            id += ":\(extraId)"
        }

        id += ":\(userCredentials.deviceIdentifier)"

        if let bundleIdentifier = userCredentials.bundleIdentifier {
            id += ":\(bundleIdentifier)"
        }

        return id
    }

    var extraIdProvider: (() -> String?)?

    public private(set) var existingConnectOptions: ConnectOptions?
    
    private let userCredentials: ClickstreamClientIdentifiers

    private var userProperties: [String: String]? {
        guard isConnectUserPropertiesEnabled else { return nil }

        return [
            "OS": "iOS",
            "OSVer": UIDevice.current.systemVersion,
            "AppVer": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unkn",
            "AppState": applicationState == .foreground ? "FG" : "BG",
            "Network": networkTypeProvider.trackingId
        ]
    }

    init(
        config: ClickstreamCourierConfig,
        userCredentials: ClickstreamClientIdentifiers,
        userDefaults: UserDefaults = .init(suiteName: "com.clickstream.courier") ?? .standard,
        userDefaultsKey: String = "connect_auth_response",
        applicationState: CourierApplicationState = .foreground,
        networkTypeProvider: NetworkType
    ) {
        self.config = config
        self.userCredentials = userCredentials
        self.extraIdProvider = { userCredentials.extraIdentifier }

        self.cachingType = CourierConnectCacheType(rawValue: config.connectConfig.tokenCachingType) ?? .disk
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey

        if cachingType == .disk,
            let data = userDefaults.data(forKey: userDefaultsKey),
            let authResponse = try? JSONDecoder().decode(CourierConnect.self, from: data),
            Self.isTokenValid(authResponse: authResponse,
                              cachingType: cachingType,
                              isTokenCacheExpiryEnabled: config.connectConfig.isTokenCacheExpiryEnabled) {

            self._cachedAuthResponse = Atomic(authResponse)
        } else {
            userDefaults.removeObject(forKey: userDefaultsKey)
            self._cachedAuthResponse = Atomic(nil)
        }

        self.isConnectUserPropertiesEnabled = config.connectConfig.isConnectUserPropertiesEnabled
        self.applicationState = applicationState
        self.networkTypeProvider = networkTypeProvider
    }

    func getConnectOptions(completion: @escaping (Result<ConnectOptions, AuthError>) -> Void) {
        if cachingType != .noop, let cachedCourierConnect = self.cachedAuthResponse,
            Self.isTokenValid(authResponse: cachedCourierConnect,
                              cachingType: self.cachingType,
                              isTokenCacheExpiryEnabled: self.config.connectConfig.isTokenCacheExpiryEnabled) {
            
            let connectOptions = connectOptions(with: cachedCourierConnect)
            self.existingConnectOptions = connectOptions
            completion(.success(connectOptions))
            return
        }

        Task {
            do {
                let courierConnect = try await executeRequest(with: userCredentials.authURLRequest)
                let connectOptions = connectOptions(with: courierConnect)
                self.existingConnectOptions = connectOptions
                completion(.success(connectOptions))
            } catch(let error) {
                self.existingConnectOptions = nil
                
                if let authError = error as? AuthError {
                    completion(.failure(authError))
                } else {
                    completion(.failure(.otherError(.init(domain: "com.clickstream.courier.auth", code: -1, userInfo: ["error": error.localizedDescription]))))
                }
            }
        }
    }

    func clearCachedAuthResponse() {
        self.cachedAuthResponse = nil
    }

    private func connectOptions(with response: CourierConnect) -> ConnectOptions {
        ConnectOptions(
            host: response.broker.host,
            port: UInt16(response.broker.port),
            keepAlive: UInt16(config.pingIntervalMs),
            clientId: clientId,
            username: userCredentials.userIdentifier,
            password: response.token,
            isCleanSession: config.isCleanSessionEnabled,
            userProperties: userProperties,
            alpn: config.connectConfig.alpn
        )
    }

    private func executeRequest(with urlRequest: URLRequest) async throws -> CourierConnect {
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                let statusCode: Int = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw AuthError.httpError(statusCode: statusCode)
            }

            let connection = try JSONDecoder().decode(CourierConnect.self, from: data)
            return connection
        } catch(let error) {
            throw AuthError.otherError(.init(domain: "com.clickstream.courier.auth", code: -1, userInfo: ["error": error.localizedDescription]))
        }
    }
}

extension CourierAuthenticationProvider {

    static func isTokenValid(authResponse: CourierConnect,
                             cachingType: CourierConnectCacheType,
                             isTokenCacheExpiryEnabled: Bool) -> Bool {

        guard isTokenCacheExpiryEnabled else {
            return true
        }

        guard cachingType == .disk,
              let expiryTimestamp = authResponse.expiryTimestamp
        else {
            return true
        }

        return (expiryTimestamp.timeIntervalSince1970 - Date().timeIntervalSince1970) >= 60
    }
}
