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
    var networkOptions: ClickstreamNetworkOptions? { get }
}

struct DefaultNetworkConfiguration: NetworkConfigurable {
    let request: URLRequest
    var networkOptions: ClickstreamNetworkOptions?

    init(request: URLRequest, networkOptions: ClickstreamNetworkOptions? = nil) {
        self.request = request
        self.networkOptions = networkOptions
    }
}
