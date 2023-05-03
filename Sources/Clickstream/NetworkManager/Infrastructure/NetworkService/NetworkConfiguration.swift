//
//  NetworkConfiguration.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol NetworkConfigurable {
    var request: URLRequest { get }
}

struct DefaultNetworkConfiguration: NetworkConfigurable {
    let request: URLRequest
    
    init(request: URLRequest) {
        self.request = request
    }
}
