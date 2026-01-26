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

fileprivate enum CourierAuthError: Error {
    
    case httpError(_ statusCode: Int)
    case decodingError
    case otherError(_ description: String)

    var errorDescription: String {
        switch self {
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .decodingError:
            return "JSON Decoding Error"
        case .otherError(let description):
            return "Other Error: \(description)"
        }
    }

    var asNSError: NSError {
        NSError(domain: "com.clickstream.courier", code: -1, userInfo: ["error_description": errorDescription])
    }

}

final class CourierAuthenticationProvider: IConnectionServiceProvider {

    private let cachingType: CourierConnectCacheType
    private let userDefaults: UserDefaults
    private let userDefaultsKey: String

    private let config: ClickstreamCourierClientConfig

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
            userDefaults.synchronize()
        }
    }

    var clientId: String {
        var id = "\(userCredentials.deviceIdentifier)"

        if let ownerId = userCredentials.extraIdentifier, !ownerId.isEmpty {
            id += ":\(ownerId)"
        }

        id += ":\(userCredentials.userIdentifier)"

        if let bundleID = userCredentials.bundleIdentifier, !bundleID.isEmpty {
            id += ":\(bundleID)"
        }

        id += ":clickstream"

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
        config: ClickstreamCourierClientConfig,
        userCredentials: ClickstreamClientIdentifiers,
        userDefaults: UserDefaults = .init(suiteName: "com.clickstream.courier") ?? .standard,
        userDefaultsKey: String = "connect_auth_response",
        applicationState: CourierApplicationState = .foreground,
        networkTypeProvider: NetworkType
    ) {
        self.config = config
        self.userCredentials = userCredentials
        self.extraIdProvider = { userCredentials.extraIdentifier }

        self.cachingType = CourierConnectCacheType(rawValue: config.courierTokenCacheType) ?? .disk
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey

        if cachingType == .disk, config.courierTokenCacheExpiryEnabled,
            let data = userDefaults.data(forKey: userDefaultsKey),
            let authResponse = try? JSONDecoder().decode(CourierConnect.self, from: data),
            Self.isCachedTokenValid(authResponse: authResponse) {

            self._cachedAuthResponse = Atomic(authResponse)
        } else {
            userDefaults.removeObject(forKey: userDefaultsKey)
            userDefaults.synchronize()
            self._cachedAuthResponse = Atomic(nil)
        }

        self.isConnectUserPropertiesEnabled = true
        self.applicationState = applicationState
        self.networkTypeProvider = networkTypeProvider
    }

    func getConnectOptions(completion: @escaping (Result<ConnectOptions, AuthError>) -> Void) {
        if cachingType == .disk, config.courierTokenCacheExpiryEnabled, let cachedAuthResponse,
            Self.isCachedTokenValid(authResponse: cachedAuthResponse) {
    
            // Fetch cached auth response and assign `ConnectOptions` to class variable
            let connectOptions = connectOptions(with: cachedAuthResponse)
            self.existingConnectOptions = connectOptions
            completion(.success(connectOptions))
            return
        }

        Task {
            do {
                var authResponse = try await executeRequest(with: userCredentials.authURLRequest)
    
                if self.cachingType == .disk {
                    // Assign `expiry_in_sec` to expiryTimestamp
                    authResponse.expiryTimestamp = Date().addingTimeInterval(authResponse.expiryInSec)
                }

                if self.cachingType != .noop {
                    // Update cached response
                    self.cachedAuthResponse = authResponse
                }

                // Convert auth response into `ConnectOptions`
                let connectOptions = connectOptions(with: authResponse)
                
                self.existingConnectOptions = connectOptions
                completion(.success(connectOptions))
            } catch(let error) {
                self.existingConnectOptions = nil

                if let courierAuthError = error as? CourierAuthError {
                    completion(.failure(.otherError(.init(domain: "com.clickstream.courier.auth", code: -1, userInfo: ["error": courierAuthError.errorDescription]))))
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
            keepAlive: UInt16(config.courierPingIntervalMillis),
            clientId: clientId,
            username: userCredentials.userIdentifier,
            password: response.token,
            isCleanSession: config.courierIsCleanSessionEnabled,
            userProperties: userProperties,
            alpn: ["mqtt"]
        )
    }

    private func executeRequest(with urlRequest: URLRequest) async throws -> CourierConnect {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let statusCode: Int = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw CourierAuthError.httpError(statusCode)
        }

        do {
            let connection = try JSONDecoder().decode(CourierConnect.self, from: data)
            return connection
        } catch {
            throw CourierAuthError.decodingError
        }
    }
    
    static func isCachedTokenValid(authResponse: CourierConnect) -> Bool {
        guard let expiryTimestamp = authResponse.expiryTimestamp else {
            return false
        }

        return (expiryTimestamp.timeIntervalSince1970 - Date().timeIntervalSince1970) < authResponse.expiryInSec
    }
}
