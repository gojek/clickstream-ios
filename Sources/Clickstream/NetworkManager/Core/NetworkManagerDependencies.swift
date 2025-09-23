//
//  NetworkManagerDependencies.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol NetworkManagerDependencies {

    init(with request: URLRequest, db: Database)

    var networkService: NetworkService { get }
    var reachability: NetworkReachability { get }
    var isConnected: Bool { get }
    var retryMech: Retryable { get }

    func getNetworkConfig() -> NetworkConfigurable
    func makeNetworkBuilder() -> NetworkBuildable
}
