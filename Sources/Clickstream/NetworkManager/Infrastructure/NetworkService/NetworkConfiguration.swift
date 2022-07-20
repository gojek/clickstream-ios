//
//  NetworkConfiguration.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol NetworkConfigurable: Requestable {
    var baseURL: URL { get }
    var headers: [String: String] { get }
}

extension NetworkConfigurable {
    
    func urlRequest() throws -> URLRequest {
        
        let url = self.baseURL
        var urlRequest = URLRequest(url: url)
        var allHeaders: [String: String] = self.headers
        self.headers.forEach({ allHeaders.updateValue($1, forKey: $0) })
        
        urlRequest.allHTTPHeaderFields = allHeaders
        return urlRequest
    }
}

public struct NetworkConfigurations: NetworkConfigurable {
    
    private(set) var baseURL: URL
    private(set) var headers: [String: String]
    
    public init(baseURL: URL,
                headers: [String: String] = [:]) {
        self.baseURL = baseURL
        self.headers = headers
    }
}
