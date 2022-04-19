//
//  NetworkManagerDependencies.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class NetworkManagerDependencies {
    
    private let database: Database
    private let networkConfigurations: NetworkConfigurations
    
    init(with networkConfigurations: NetworkConfigurations,
         db: Database) {
        self.database = db
        self.networkConfigurations = networkConfigurations
    }
    
    private let networkQueue = SerialQueue(label: Constants.QueueIdentifiers.network.rawValue, qos: .utility)
    
    private let daoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue,
                                       qos: .utility,
                                       attributes: .concurrent)

    private lazy var networkService: DefaultNetworkService<DefaultSocketHandler> = {
        return DefaultNetworkService<DefaultSocketHandler>(with: networkConfigurations, performOnQueue: networkQueue)
    }()
    
    private lazy var reachability: NetworkReachability = {
        let reachability = try! DefaultNetworkReachability(with: networkQueue)
        return reachability
    }()
    
    private lazy var deviceStatus: DefaultDeviceStatus = {
        let deviceStatus = DefaultDeviceStatus(performOnQueue: networkQueue)
        return deviceStatus
    }()
    
    private lazy var appStateNotifier: AppStateNotifierService = {
        return DefaultAppStateNotifierService(with: networkQueue)
    }()
    
    private lazy var defaultPersistence: DefaultDatabaseDAO<EventRequest> = {
        return DefaultDatabaseDAO<EventRequest>(database: database,
                                                performOnQueue: daoQueue)
    }()
    
    private lazy var keepAliveService: KeepAliveService = {
        if Clickstream.isInitialisedOnBackgroundQueue {
            return DefaultKeepAliveServiceWithSafeTimer(with: networkQueue,
                                           duration: Clickstream.constraints.connectionRetryDuration,
                                           reachability: reachability)
        } else {
            return DefaultKeepAliveService(with: networkQueue,
                                           duration: Clickstream.constraints.connectionRetryDuration,
                                           reachability: reachability)
        }
    }()
    
    private lazy var retryMech: Retryable = {
       return DefaultRetryMechanism(networkService: networkService,
                                    reachability: reachability,
                                    deviceStatus: deviceStatus,
                                    appStateNotifier: appStateNotifier,
                                    performOnQueue: networkQueue,
                                    persistence: defaultPersistence,
                                    keepAliveService: keepAliveService)
    }()
    
    func makeNetworkBuilder() -> NetworkBuildable {
        return DefaultNetworkBuilder(networkConfigs: networkConfigurations, retryMech: retryMech, performOnQueue: networkQueue)
    }
}
