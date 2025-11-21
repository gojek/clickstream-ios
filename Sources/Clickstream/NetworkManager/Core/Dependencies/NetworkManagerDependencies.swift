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
    private let networkOptions: ClickstreamNetworkOptions

    init(with request: URLRequest, db: Database, networkOptions: ClickstreamNetworkOptions) {
        self.database = db
        self.request = request
        self.networkOptions = networkOptions
    }

    private let socketNetworkQueue = SerialQueue(label: Constants.QueueIdentifiers.network.rawValue, qos: .utility)
    private let socketDaoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue, qos: .utility, attributes: .concurrent)

    private let courierNetworkQueue = SerialQueue(label: Constants.CourierQueueIdentifiers.network.rawValue, qos: .utility)
    private let courierDaoQueue = DispatchQueue(label: Constants.CourierQueueIdentifiers.dao.rawValue, qos: .utility, attributes: .concurrent)

    private lazy var reachability: NetworkReachability = {
        DefaultNetworkReachability(with: socketNetworkQueue)
    }()

    private lazy var deviceStatus: DefaultDeviceStatus = {
        DefaultDeviceStatus(performOnQueue: socketNetworkQueue)
    }()

    private lazy var socketAppStateNotifier: AppStateNotifierService = {
        DefaultAppStateNotifierService(with: socketNetworkQueue)
    }()

    private lazy var courierAppStateNotifier: AppStateNotifierService = {
        DefaultAppStateNotifierService(with: courierNetworkQueue)
    }()

    private lazy var socketPersistence: DefaultDatabaseDAO<EventRequest> = {
        DefaultDatabaseDAO<EventRequest>(database: database,
                                         performOnQueue: socketDaoQueue)
    }()

    private lazy var courierPersistance: DefaultDatabaseDAO<CourierEventRequest> = {
        DefaultDatabaseDAO<CourierEventRequest>(database: database,
                                         performOnQueue: courierDaoQueue)
    }()

    private lazy var keepAliveService: KeepAliveService = {
        DefaultKeepAliveServiceWithSafeTimer(with: socketNetworkQueue,
                                             duration: Clickstream.configurations.connectionRetryDuration,
                                             reachability: reachability)
    }()

    private lazy var websocketNetworkService: NetworkService = {
        WebsocketNetworkService<DefaultSocketHandler>(with: getNetworkConfig(),
                                                      performOnQueue: socketNetworkQueue)
    }()
    
    private lazy var courierNetworkService: NetworkService = {
        CourierNetworkService<DefaultCourierHandler>(with: getNetworkConfig(),
                                                     performOnQueue: courierNetworkQueue)
    }()

    private lazy var websocketRetryMech: WebsocketRetryMechanism = {
        WebsocketRetryMechanism(networkService: websocketNetworkService,
                                reachability: reachability,
                                deviceStatus: deviceStatus,
                                appStateNotifier: socketAppStateNotifier,
                                performOnQueue: socketNetworkQueue,
                                persistence: socketPersistence,
                                keepAliveService: keepAliveService)
    }()

    private lazy var courierRetryMech: CourierRetryMechanism = {
        CourierRetryMechanism(networkOptions: networkOptions,
                              networkService: courierNetworkService,
                              reachability: reachability,
                              deviceStatus: deviceStatus,
                              appStateNotifier: courierAppStateNotifier,
                              performOnQueue: courierNetworkQueue,
                              persistence: courierPersistance)
    }()

    private func getNetworkConfig() -> DefaultNetworkConfiguration {
        DefaultNetworkConfiguration(request: request, networkOptions: networkOptions)
    }

    func makeNetworkBuilder() -> WebsocketNetworkBuilder {
        WebsocketNetworkBuilder(networkConfigs: getNetworkConfig(),
                                retryMech: websocketRetryMech,
                                performOnQueue: socketNetworkQueue)
    }

    func makeCourierNetworkBuilder() -> CourierNetworkBuilder {
        CourierNetworkBuilder(networkConfigs: getNetworkConfig(),
                              retryMech: courierRetryMech,
                              performOnQueue: courierNetworkQueue)
    }

    var isSocketConnected: Bool {
        websocketNetworkService.isConnected
    }

    var isCourierConnected: Bool {
        courierNetworkService.isConnected
    }

    func provideClientIdentifiers(with identifiers: ClickstreamClientIdentifiers, topic: String) {
        guard let courierIdentifiers = identifiers as? CourierIdentifiers else {
            return
        }

        courierRetryMech.configureIdentifiers(with: courierIdentifiers, topic: topic)
    }
    
    func removeClientIdentifiers() {
        courierRetryMech.removeIdentifiers()
    }
}
