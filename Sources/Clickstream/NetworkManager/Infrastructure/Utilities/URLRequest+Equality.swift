//
//  URLRequest+Equality.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 08/04/24.
//  Copyright © 2024 Gojek. All rights reserved.
//

import Foundation

extension URLRequest {
    func isEqual(to: URLRequest?) -> Bool {
        guard let to = to else {
            return false
        }
        guard let bearerSelf = self.allHTTPHeaderFields?["Authorization"] else { return false }
        guard let bearerProvided = to.allHTTPHeaderFields?["Authorization"] else { return false }
        if self.url == to.url && bearerSelf == bearerProvided {
            return true
        }
        return false
    }
}
