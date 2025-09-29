//
//  NetworkDependencies.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 29/09/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

final class DefaultNetworkDependencies {
    
    private(set) var request: URLRequest
    private(set) var database: Database

    private(set) var networkQueue = SerialQueue(label: Constants.QueueIdentifiers.network.rawValue, qos: .utility)
    private(set) var daoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue,
                                              qos: .utility,
                                              attributes: .concurrent)
    
    init(with urlRequest: URLRequest, db: Database) throws {
        database = db
        request = urlRequest
    }
    
    private(set) lazy var deviceStatus: DefaultDeviceStatus = {
        let deviceStatus = DefaultDeviceStatus(performOnQueue: networkQueue)
        return deviceStatus
    }()
    
    private(set) lazy var appStateNotifier: AppStateNotifierService = {
        return DefaultAppStateNotifierService(with: networkQueue)
    }()
    
    private(set) lazy var defaultPersistence: DefaultDatabaseDAO<EventRequest> = {
        return DefaultDatabaseDAO<EventRequest>(database: database,
                                                performOnQueue: daoQueue)
    }()
    
    private(set) lazy var keepAliveService: KeepAliveService = {
        return DefaultKeepAliveServiceWithSafeTimer(with: networkQueue,
                                                    duration: Clickstream.configurations.connectionRetryDuration,
                                                    reachability: reachability)
    }()

    private(set) lazy var reachability: NetworkReachability = {
        let reachability = DefaultNetworkReachability(with: networkQueue)
        return reachability
    }()
}
