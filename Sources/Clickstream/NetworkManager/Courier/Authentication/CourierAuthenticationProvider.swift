//
//  CourierAuthenticationProvider.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 10/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierCore

final class CourierAuthenticationProvider: IConnectionServiceProvider {

    private let cachingType: CourierConnectCacheType
    private let userDefaults: UserDefaults
    private let userDefaultsKey: String

    private let config: ClickstreamCourierConfig

    private let isConnectUserPropertiesEnabled: Bool
    private let networkTypeProvider: NetworkType
    private let applicationState: UIApplication.State

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
    
    private let userCredentials: ClickstreamCourierUserCredentials


    private var userProperties: [String: String]? {
        guard isConnectUserPropertiesEnabled else { return nil }

        return [
            "OS": "iOS",
            "OSVer": UIDevice.current.systemVersion,
            "AppVer": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unkn",
            "AppState": applicationState == .active ? "FG" : "BG",
            "Network": networkTypeProvider.trackingId
        ]
    }

    init(
        config: ClickstreamCourierConfig,
        userCredentials: ClickstreamCourierUserCredentials,
        cachingType: CourierConnectCacheType = .noop,
        userDefaults: UserDefaults = .init(suiteName: "com.clickstream.courier") ?? .standard,
        userDefaultsKey: String = "connect_auth_response",
        isConnectUserPropertiesEnabled: Bool = false,
        applicationState: UIApplication.State,
        networkTypeProvider: NetworkType
    ) {
        self.config = config
        self.userCredentials = userCredentials
        self.extraIdProvider = { userCredentials.extraIdentifier }

        self.cachingType = cachingType
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey

        if cachingType == .disk,
            let data = userDefaults.data(forKey: userDefaultsKey),
            let authResponse = try? JSONDecoder().decode(CourierConnect.self, from: data),
            Self.isTokenValid(authResponse: authResponse,
                              cachingType: cachingType,
                              isTokenCacheExpiryEnabled: !config.connectConfig.isTokenCacheExpiryEnabled) {

            self._cachedAuthResponse = Atomic(authResponse)
        } else {
            userDefaults.removeObject(forKey: userDefaultsKey)
            self._cachedAuthResponse = Atomic(nil)
        }

        self.isConnectUserPropertiesEnabled = isConnectUserPropertiesEnabled
        self.applicationState = applicationState
        self.networkTypeProvider = networkTypeProvider
    }

    func getConnectOptions(completion: @escaping (Result<ConnectOptions, AuthError>) -> Void) {
        if cachingType != .noop, let cachedCourierConnect = self.cachedAuthResponse,
            Self.isTokenValid(authResponse: cachedCourierConnect,
                              cachingType: self.cachingType,
                              isTokenCacheExpiryEnabled: !self.config.connectConfig.isTokenCacheExpiryEnabled) {
            
            let connectOptions = connectOptions(with: cachedCourierConnect)
            self.existingConnectOptions = connectOptions
            completion(.success(connectOptions))
            return
        }

        Task {
            do {
                var components = URLComponents()
                components.scheme = "https"
                components.host = self.config.connectConfig.baseURL
                components.path = self.config.connectConfig.authURLPath

                let courierConnect = try await self.executeRequest(urlCachePolicy: .returnCacheDataElseLoad,
                                                                   timeoutInterval: self.config.authenticationTimeoutInterval,
                                                                   url: components.url)

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
            keepAlive: UInt16(config.connectConfig.pingIntervalMs),
            clientId: clientId,
            username: userCredentials.userIdentifier,
            password: response.token,
            isCleanSession: config.connectConfig.isCleanSessionEnabled,
            userProperties: userProperties,
            alpn: config.connectConfig.alpn
        )
    }

    private func executeRequest(
        urlCachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeoutInterval: TimeInterval = 10,
        url: URL?,
    ) async throws -> CourierConnect {
        guard let url else {
            throw AuthError.otherError(.init(domain: "com.clickstream.courier.auth", code: -1, userInfo: ["error": "Invalid auth url"]))
        }

        let request = URLRequest(url: url, cachePolicy: urlCachePolicy, timeoutInterval: timeoutInterval)
        
        let response: (Data, URLResponse)

        do {
            response = try await URLSession.shared.data(for: request)
        } catch(let error) {
            throw AuthError.otherError(.init(domain: "com.clickstream.courier.auth", code: -1, userInfo: ["error": error.localizedDescription]))
        }
        
        guard let httpResponse = response.1 as? HTTPURLResponse, 100..<200 ~= httpResponse.statusCode else {
            let statusCode: Int = (response.1 as? HTTPURLResponse)?.statusCode ?? -1
            throw AuthError.httpError(statusCode: statusCode)
        }

        do {
            let connection = try JSONDecoder().decode(CourierConnect.self, from: response.0)
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
