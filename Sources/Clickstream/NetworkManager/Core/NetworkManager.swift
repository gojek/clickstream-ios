//
//  NetworkManagerDependencies.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol NetworkManager {
    
    init(with dependencies: DefaultNetworkDependencies)

    var networkService: NetworkService { get }
    var retryMech: Retryable { get }
    var isConnected: Bool { get }

    func getNetworkConfig() -> NetworkConfigurable
    func makeNetworkBuilder() -> NetworkBuildable
}
