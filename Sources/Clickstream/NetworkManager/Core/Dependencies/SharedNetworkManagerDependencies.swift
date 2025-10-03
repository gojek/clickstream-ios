//
//  SharedNetworkManagerDependencies.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 29/09/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation


/// A class equivalent to `NetworkManagerDependencies.swift`
/// This class will be the main network manager dependencies, to support multiple network protocols
final class SharedNetworkManagerDependencies {

    private var request: URLRequest
    private let database: Database

    private let dispatcherOptions: Set<ClickstreamDispatcherOption>

    init(with request: URLRequest,
         db: Database,
         options: Set<ClickstreamDispatcherOption>) {

        self.database = db
        self.request = request
        self.dispatcherOptions = options
    }

    private let networkQueue = SerialQueue(label: Constants.QueueIdentifiers.network.rawValue, qos: .utility)
    private let daoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue, qos: .utility, attributes: .concurrent)

    private lazy var reachability: NetworkReachability = {
        DefaultNetworkReachability(with: networkQueue)
    }()

    private lazy var deviceStatus: DefaultDeviceStatus = {
        DefaultDeviceStatus(performOnQueue: networkQueue)
    }()

    private lazy var appStateNotifier: AppStateNotifierService = {
        DefaultAppStateNotifierService(with: networkQueue)
    }()

    private lazy var defaultPersistence: DefaultDatabaseDAO<EventRequest> = {
        DefaultDatabaseDAO<EventRequest>(database: database,
                                         performOnQueue: daoQueue)
    }()

    private lazy var keepAliveService: KeepAliveService = {
        DefaultKeepAliveServiceWithSafeTimer(with: networkQueue,
                                             duration: Clickstream.configurations.connectionRetryDuration,
                                             reachability: reachability)
    }()

    private lazy var networkService: NetworkService = {
        WebsocketNetworkService<DefaultSocketHandler>(with: getNetworkConfig(),
                                                      performOnQueue: networkQueue)
    }()

    private lazy var retryMech: Retryable = {
        WebsocketRetryMechanism(networkService: networkService,
                                reachability: reachability,
                                deviceStatus: deviceStatus,
                                appStateNotifier: appStateNotifier,
                                performOnQueue: networkQueue,
                                persistence: defaultPersistence,
                                keepAliveService: keepAliveService)
    }()

    private func getNetworkConfig() -> DefaultNetworkConfiguration {
        DefaultNetworkConfiguration(request: request)
    }

    func makeNetworkBuilder() -> NetworkBuildable {
        WebsocketNetworkBuilder(networkConfigs: getNetworkConfig(),
                                retryMech: retryMech,
                                performOnQueue: networkQueue)
    }

    var isSocketConnected: Bool {
        networkService.isConnected
    }
}
