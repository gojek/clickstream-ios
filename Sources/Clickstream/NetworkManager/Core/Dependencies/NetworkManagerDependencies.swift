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

    private let courierNetworkQueue = SerialQueue(label: Constants.CourierQueueIdentifiers.network.rawValue, qos: .utility)
    private let courierDaoQueue = DispatchQueue(label: Constants.CourierQueueIdentifiers.dao.rawValue, qos: .utility, attributes: .concurrent)

    private lazy var courierReachability: NetworkReachability = {
        DefaultNetworkReachability(with: courierNetworkQueue)
    }()

    private lazy var courierAppStateNotifier: AppStateNotifierService = {
        DefaultAppStateNotifierService(with: courierNetworkQueue)
    }()

    private lazy var courierPersistance: DefaultDatabaseDAO<CourierEventRequest> = {
        DefaultDatabaseDAO<CourierEventRequest>(database: database,
                                         performOnQueue: courierDaoQueue)
    }()
    
    private lazy var courierNetworkService: NetworkService = {
        CourierNetworkService<DefaultCourierHandler>(with: getNetworkConfig(),
                                                     performOnQueue: courierNetworkQueue)
    }()

    private lazy var courierRetryMech: CourierRetryMechanism? = {
        guard !networkOptions.enableCourierMechanismV2 else { return nil }
        return CourierRetryMechanism(networkOptions: networkOptions,
                              networkService: courierNetworkService,
                              reachability: courierReachability,
                              appStateNotifier: courierAppStateNotifier,
                              performOnQueue: courierNetworkQueue,
                              persistence: courierPersistance)
    }()

    private lazy var courierRetryMechV2: CourierRetryMechanismV2? = {
        guard networkOptions.enableCourierMechanismV2 else { return nil }
        return CourierRetryMechanismV2(networkOptions: networkOptions,
                              networkService: courierNetworkService,
                              reachability: courierReachability,
                              appStateNotifier: courierAppStateNotifier,
                              performOnQueue: courierNetworkQueue,
                              persistence: courierPersistance)
    }()

    private func getNetworkConfig() -> DefaultNetworkConfiguration {
        DefaultNetworkConfiguration(request: request, networkOptions: networkOptions)
    }

    func makeCourierNetworkBuilder() -> CourierNetworkBuilder {
        CourierNetworkBuilder(networkConfigs: getNetworkConfig(),
                              retryMech: courierRetryMech,
                              retryMechV2: courierRetryMechV2,
                              performOnQueue: courierNetworkQueue)
    }

    var isCourierConnected: Bool {
        courierNetworkService.isConnected
    }

    func provideClientIdentifiers(with identifiers: ClickstreamClientIdentifiers,
                                  topic: String,
                                  authProvider: IConnectionServiceProvider,
                                  pubSubAnalytics: ICourierEventHandler?) {

        if let courierRetryMechV2 {
            courierRetryMechV2.configureIdentifiers(with: identifiers,
                                                    topic: topic,
                                                    authProvider: authProvider,
                                                    pubSubAnalytics: pubSubAnalytics)
        } else {
            courierRetryMech?.configureIdentifiers(with: identifiers,
                                                   topic: topic,
                                                   authProvider: authProvider,
                                                   pubSubAnalytics: pubSubAnalytics)
        }
    }

    func removeClientIdentifiers() {
        if let courierRetryMechV2 {
            courierRetryMechV2.removeIdentifiers()
        } else {
            courierRetryMech?.removeIdentifiers()
        }
    }
}
