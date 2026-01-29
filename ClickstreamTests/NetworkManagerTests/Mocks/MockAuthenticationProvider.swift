//
//  MockAuthenticationProvider.swift
//  ClickstreamTests
//
//  Created by GitHub Copilot on 27/01/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

import Foundation
import CourierCore
@testable import Clickstream

final class MockAuthenticationProvider: IConnectionServiceProvider {

    var clientId: String {
        "client-id"
    }
    
    var extraIdProvider: (() -> String?)?
    
    
    var cachedAuthResponse: CourierConnect?
    var shouldReturnCachedResponse: Bool = false
    var shouldFailWithError: AuthError?
    var existingConnectOptions: ConnectOptions?
    
    init(cachedResponse: CourierConnect? = nil) {
        self.cachedAuthResponse = cachedResponse
    }
    
    func getConnectOptions(completion: @escaping (Result<ConnectOptions, AuthError>) -> Void) {
        if let error = shouldFailWithError {
            completion(.failure(error))
            return
        }
        
        let mockOptions = ConnectOptions(
            host: "mock.host.com",
            port: 1883,
            keepAlive: 60,
            clientId: "mock-client-id",
            username: "mock-username",
            password: "mock-password",
            isCleanSession: true
        )
        
        existingConnectOptions = mockOptions
        completion(.success(mockOptions))
    }
}
