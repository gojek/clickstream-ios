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

/// A class equivalent to `NetworkManagerDependencies.swift`
/// This class will be the main network manager dependencies, to support multiple network protocols
final class SharedNetworkManagerDependencies {

    private var request: URLRequest
    private let database: Database

    init(with request: URLRequest, db: Database) {
        self.database = db
        self.request = request
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
                              courierConfig: makeCourierConfig())
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
}

extension SharedNetworkManagerDependencies {

    private func makeCourierConfig() -> MQTTClientConfig {
        let topics: [String: QoS] = ["clickstream/publish": .one]
        let messageAdapters: [MessageAdapter] = [
            JSONMessageAdapter(),
            ProtobufMessageAdapter()
        ]

        return MQTTClientConfig(topics: topics,
                                authService: getAuthService(),
                                messageAdapters: messageAdapters,
                                isMessagePersistenceEnabled: true,
                                autoReconnectInterval: 1,
                                maxAutoReconnectInterval: 1,
                                enableAuthenticationTimeout: true,
                                authenticationTimeoutInterval: 3.0,
                                connectTimeoutPolicy: getconnectTimeoutPolicy(),
                                idleActivityTimeoutPolicy: getIdderActivityTimeoutPolicy(),
                                messagePersistenceTTLSeconds: 1,
                                messageCleanupInterval: 1,
                                shouldInitializeCoreDataPersistenceContext: true)
    }
    
    func getAuthService() -> IConnectionServiceProvider {
        fatalError()
    }
    
    func getconnectTimeoutPolicy() -> IConnectTimeoutPolicy {
        fatalError()
    }
    
    func getIdderActivityTimeoutPolicy() -> IdleActivityTimeoutPolicyProtocol {
        fatalError()
    }
}
