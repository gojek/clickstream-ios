//
//  NetworkManagerDependencies.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import CourierCore
import CourierMQTT
import Foundation

final class NetworkManagerDependencies {
    
    private var request: URLRequest
    private let database: Database
    private let networkOptions: ClickstreamNetworkOptions
    private var courierPreAuthIdentifiers: ClickstreamClientPreAuthIdentifiers?
    private var courierPostAuthIdentifiers: ClickstreamClientPostAuthIdentifiers?

    init(with request: URLRequest, db: Database, networkOptions: ClickstreamNetworkOptions) {
        self.database = db
        self.request = request
        self.networkOptions = networkOptions
    }

    private let socketNetworkQueue = SerialQueue(label: Constants.QueueIdentifiers.network.rawValue, qos: .utility)
    private let socketDaoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue, qos: .utility, attributes: .concurrent)

    private let courierPreAuthNetworkQueue = SerialQueue(label: Constants.CourierQueueIdentifiers.networkPreAuth.rawValue, qos: .utility)
    private let courierPostAuthNetworkQueue = SerialQueue(label: Constants.CourierQueueIdentifiers.networkPostAuth.rawValue, qos: .utility)
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

    private lazy var courierPreAuthAppStateNotifier: AppStateNotifierService = {
        DefaultAppStateNotifierService(with: courierPreAuthNetworkQueue)
    }()

    private lazy var courierPostAuthAppStateNotifier: AppStateNotifierService = {
        DefaultAppStateNotifierService(with: courierPostAuthNetworkQueue)
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
    
    private lazy var courierPreAuthNetworkService: NetworkService = {
        CourierNetworkService<DefaultCourierHandler>(with: getNetworkConfig(),
                                                     performOnQueue: courierPreAuthNetworkQueue)
    }()

    private lazy var courierPostAuthNetworkService: NetworkService = {
        CourierNetworkService<DefaultCourierHandler>(with: getNetworkConfig(),
                                                     performOnQueue: courierPostAuthNetworkQueue)
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

    private lazy var courierPreAuthRetryMech: CourierRetryMechanism = {
        CourierRetryMechanism(networkOptions: networkOptions,
                              networkService: courierPreAuthNetworkService,
                              reachability: reachability,
                              deviceStatus: deviceStatus,
                              appStateNotifier: courierPreAuthAppStateNotifier,
                              performOnQueue: courierPreAuthNetworkQueue,
                              persistence: courierPersistance)
    }()

    private lazy var courierPostAuthRetryMech: CourierRetryMechanism = {
        CourierRetryMechanism(networkOptions: networkOptions,
                              networkService: courierPostAuthNetworkService,
                              reachability: reachability,
                              deviceStatus: deviceStatus,
                              appStateNotifier: courierPostAuthAppStateNotifier,
                              performOnQueue: courierPostAuthNetworkQueue,
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
        if courierPostAuthIdentifiers != nil {
            return CourierNetworkBuilder(networkConfigs: getNetworkConfig(),
                                         retryMech: courierPostAuthRetryMech,
                                         performOnQueue: courierPostAuthNetworkQueue)
        } else {
            return CourierNetworkBuilder(networkConfigs: getNetworkConfig(),
                                  retryMech: courierPreAuthRetryMech,
                                  performOnQueue: courierPreAuthNetworkQueue)
        }
    }

    var isSocketConnected: Bool {
        websocketNetworkService.isConnected
    }

    var isCourierConnected: Bool {
        if courierPostAuthIdentifiers != nil {
            courierPostAuthNetworkService.isConnected
        } else {
            courierPreAuthNetworkService.isConnected
        }
    }

    func providePreAuthClientIdentifiers(with identifiers: ClickstreamClientPreAuthIdentifiers,
                                         topic: String,
                                         authProvider: IConnectionServiceProvider,
                                         pubSubAnalytics: ICourierEventHandler?) {

        courierPreAuthIdentifiers = identifiers
        courierPreAuthRetryMech.configureIdentifiers(with: identifiers,
                                                     topic: topic,
                                                     authProvider: authProvider,
                                                     pubSubAnalytics: pubSubAnalytics)
    }

    func providePostAuthClientIdentifiers(with identifiers: ClickstreamClientPostAuthIdentifiers,
                                          topic: String,
                                          authProvider: IConnectionServiceProvider,
                                          pubSubAnalytics: ICourierEventHandler?) {

        courierPostAuthIdentifiers = identifiers
        courierPostAuthRetryMech.configureIdentifiers(with: identifiers,
                                                      topic: topic,
                                                      authProvider: authProvider,
                                                      pubSubAnalytics: pubSubAnalytics)
    }

    func removePreAuthClientIdentifiers() {
        courierPreAuthRetryMech.removeIdentifiers()
    }

    func removePostAuthClientIdentifiers() {
        courierPostAuthRetryMech.removeIdentifiers()
    }
}
