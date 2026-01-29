//
//  CourierAuthProvider.swift
//  Example
//
//  Created by Luqman Fauzi on 27/01/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

import CourierCore
import CourierMQTT
import Clickstream
import Foundation
import Reachability

enum CourierApplicationState: String {
    case background, foreground
}

final class CourierAuthProvider: IConnectionServiceProvider {

    private let applicationState: CourierApplicationState
    private let networkTypeProvider: Reachability

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
        return [
            "OS": "iOS",
            "OSVer": UIDevice.current.systemVersion,
            "AppVer": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unkn",
            "AppState": applicationState == .foreground ? "FG" : "BG",
            "Network": networkTypeProvider.connection.description,
        ]
    }

    init(
        userCredentials: ClickstreamClientIdentifiers,
        applicationState: CourierApplicationState = .foreground,
        networkTypeProvider: Reachability
    ) {
        self.userCredentials = userCredentials
        self.extraIdProvider = { userCredentials.extraIdentifier }
        self.applicationState = applicationState
        self.networkTypeProvider = networkTypeProvider
    }

    func getConnectOptions(completion: @escaping (Result<ConnectOptions, AuthError>) -> Void) {
        Task {
            do {
                var authResponse = try await executeRequest()

                // Convert auth response into `ConnectOptions`
                let connectOptions = connectOptions(with: authResponse)

                self.existingConnectOptions = connectOptions
                completion(.success(connectOptions))
            } catch(let error) {
                self.existingConnectOptions = nil
                completion(.failure(.otherError(.init(domain: "com.clickstream.courier.auth", code: -1, userInfo: ["error": error.localizedDescription]))))
            }
        }
    }

    func clearCachedAuthResponse() {
        self.existingConnectOptions = nil
    }

    private func connectOptions(with response: CourierConnect) -> ConnectOptions {
        ConnectOptions(
            host: response.broker.host,
            port: UInt16(response.broker.port),
            keepAlive: UInt16(10),
            clientId: clientId,
            username: userCredentials.userIdentifier,
            password: response.token,
            isCleanSession: false,
            userProperties: userProperties,
            alpn: ["mqtt"]
        )
    }
    
    private func constructURLRequest() throws -> URLRequest {
        let baseUrl: String = "https://example.com"
        let path = "/courier/v1/token"
        let queryItems: [URLQueryItem] = [URLQueryItem(name: "token_type", value: "cs")]

        guard var urlComponents = URLComponents(string: baseUrl) else {
            throw URLError(.badURL)
        }
        urlComponents.path = path
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        return URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10.0)
    }

    private func executeRequest() async throws -> CourierConnect {
        let urlRequest = try constructURLRequest()
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let statusCode: Int = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw AuthError.httpError(statusCode: statusCode)
        }

        do {
            let connection = try JSONDecoder().decode(CourierConnect.self, from: data)
            return connection
        } catch(let error) {
            throw AuthError.otherError(.init(domain: "com.clickstream.courier.auth", code: -1, userInfo: ["error": error.localizedDescription]))
        }
    }
}
