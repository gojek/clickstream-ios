//
//  NetworkManagerDependencies.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class NetworkManagerDependencies {
    
    private var request: URLRequest
    private let database: Database
    private let eventDispatcherConfig: ClickstreamEventTypeDispatcherConfig

    init(with request: URLRequest,
         db: Database,
         eventDispatcherConfig: ClickstreamEventTypeDispatcherConfig) {
        self.database = db
        self.request = request
        self.eventDispatcherConfig = eventDispatcherConfig
    }
    
    private let networkQueue = SerialQueue(label: Constants.QueueIdentifiers.network.rawValue, qos: .utility)
    
    private let daoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue,
                                       qos: .utility,
                                       attributes: .concurrent)
    
    private func getNetworkConfig() -> DefaultNetworkConfiguration {
        return DefaultNetworkConfiguration(request: request)
    }

    private lazy var websocketNetworkService: NetworkService = {
        return DefaultNetworkService<DefaultSocketHandler>(with: getNetworkConfig(),
                                                            performOnQueue: networkQueue)
    }()
    
    private lazy var courierNetworkService: NetworkService = {
        return DefaultNetworkService<DefaultCourierHandler>(with: getNetworkConfig(),
                                                            performOnQueue: networkQueue)
    }()
    
    private lazy var reachability: NetworkReachability = {
        let reachability = DefaultNetworkReachability(with: networkQueue)
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
        return DefaultKeepAliveServiceWithSafeTimer(with: networkQueue,
                                                    duration: Clickstream.configurations.connectionRetryDuration,
                                                    reachability: reachability)
    }()
    
    private lazy var retryMech: Retryable = {
       return DefaultRetryMechanism(websocketNetworkService: websocketNetworkService,
                                    courierNetworkService: courierNetworkService,
                                    reachability: reachability,
                                    deviceStatus: deviceStatus,
                                    appStateNotifier: appStateNotifier,
                                    performOnQueue: networkQueue,
                                    persistence: defaultPersistence,
                                    keepAliveService: keepAliveService,
                                    eventDispatcherConfig: eventDispatcherConfig)
    }()
    
    func makeNetworkBuilder() -> NetworkBuildable {
        return DefaultNetworkBuilder(networkConfigs: getNetworkConfig(), retryMech: retryMech, performOnQueue: networkQueue)
    }
    
    var isSocketConnected: Bool {
        websocketNetworkService.isConnected
    }

    var isCourierConnected: Bool {
        courierNetworkService.isConnected
    }
}
