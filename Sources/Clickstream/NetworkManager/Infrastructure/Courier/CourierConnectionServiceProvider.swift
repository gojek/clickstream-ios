//
//  CourierConnectionServiceProvider.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 16/09/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierCore

final class CourierConnectionServiceProvider: IConnectionServiceProvider {    
    
    let clientId: String
    var extraIdProvider: (() -> String?)?

    init(clientId: String, extraIdProvider: String) {
        self.clientId = clientId
        self.extraIdProvider = { extraIdProvider }
    }

    func getConnectOptions(completion: @escaping (Result<ConnectOptions, AuthError>) -> Void) {
        
    }
}
