//
//  SharedNetworkManagerDependencies.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 29/09/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierCore
import CourierMQTT
import CourierProtobuf
import Reachability

/// A class equivalent to `NetworkManagerDependencies.swift`
/// This class will be the main network manager dependencies, to support multiple network protocols
final class SharedNetworkManagerDependencies {

    private var request: URLRequest
    private let database: Database
    private let courierConfig: ClickstreamCourierConfig

    init(with request: URLRequest, db: Database, courierConfig: ClickstreamCourierConfig) {
        self.database = db
        self.request = request
        self.courierConfig = courierConfig
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

    private lazy var websocketNetworkService: NetworkService = {
        WebsocketNetworkService<DefaultSocketHandler>(with: getNetworkConfig(),
                                                      performOnQueue: networkQueue)
    }()
    
    private lazy var courierNetworkService: NetworkService = {
        CourierNetworkService(with: getNetworkConfig(),
                              performOnQueue: networkQueue,
                              courierConfig: courierConfig)
    }()

    private lazy var websocketRetryMech: Retryable = {
        WebsocketRetryMechanism(networkService: websocketNetworkService,
                                reachability: reachability,
                                deviceStatus: deviceStatus,
                                appStateNotifier: appStateNotifier,
                                performOnQueue: networkQueue,
                                persistence: defaultPersistence,
                                keepAliveService: keepAliveService)
    }()

    private lazy var courierRetryMech: Retryable = {
        CourierRetryMechanism(networkService: courierNetworkService,
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
                                retryMech: websocketRetryMech,
                                performOnQueue: networkQueue)
    }

    func makeCourierNetworkBuilder() -> NetworkBuildable {
        CourierNetworkBuilder(networkConfigs: getNetworkConfig(),
                              retryMech: courierRetryMech,
                              performOnQueue: networkQueue)
    }

    var isSocketConnected: Bool {
        websocketNetworkService.isConnected
    }

    var isCourierConnected: Bool {
        courierNetworkService.isConnected
    }

    func configureCourierSession(with userCredentials: ClickstreamCourierUserCredentials) async {
        guard let networkService = self.courierNetworkService as? CourierNetworkService else {
            return
        }

        await networkService.configureCourierClient(with: userCredentials)
        await networkService.establishConnection()
    }
}

