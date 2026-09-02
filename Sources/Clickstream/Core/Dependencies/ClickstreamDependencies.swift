//
//  ClickstreamDependencies.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import CourierCore
import Foundation

/// A class that generates all the dependencies of the Clickstream SDK.
final class DefaultClickstreamDependencies {
    
    private let request: URLRequest
    private let database: Database
    private var networkManagerDependencies: NetworkManagerDependencies!

    private let samplerConfiguration: EventSamplerConfiguration?

    private let networkOptions: ClickstreamNetworkOptions

    var isCourierConnected: Bool {
        networkManagerDependencies.isCourierConnected
    }

    init(with request: URLRequest,
         samplerConfiguration: EventSamplerConfiguration? = nil,
         networkOptions: ClickstreamNetworkOptions) throws {

        self.request = request
        self.samplerConfiguration = samplerConfiguration
        self.networkOptions = networkOptions

        let db = try DefaultDatabase(qos: .WAL,
                                     recoveryEnabled: Clickstream.dbCorruptionRecoveryEnabled)
        database = db
        networkManagerDependencies = NetworkManagerDependencies(with: request, db: db, networkOptions: networkOptions)
    }

    /**
        Initializes an instance of the API with the given configurations.
        A NetworkBuildable instance. This instance acts as the only source of NetworkBuildable,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var courierNetworkBuilder: any NetworkBuildable = {
         networkManagerDependencies.makeCourierNetworkBuilder()
    }()

    /** A CourierEventWarehouser instance.
        This instance acts as the only source of CourierEventWarehouser,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var courierEventWarehouser: CourierEventWarehouser = {
        EventSchedulerDependencies(
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        ).makeCourierEventWarehouser()
    }()

    /**
        CourierEventProcessor instance.
        This instance acts as the only source of CourierEventProcessor, hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var courierEventProcessor: CourierEventProcessor = {
        EventProcessorDependencies(
            courierEventWarehouser: courierEventWarehouser,
            courierEventSampler: courierEventSampler,
            networkOptions: networkOptions,
        ).makeCourierEventProcessor()
    }()
    
    lazy var courierEventSampler: EventSampler? = {
        guard let samplerConfiguration else { return nil }
        return DefaultEventSampler(config: samplerConfiguration)
    }()
}

extension DefaultClickstreamDependencies {

    func provideAuthClientIdentifiers(with identifiers: ClickstreamClientIdentifiers,
                                      topic: String,
                                      authProvider: IConnectionServiceProvider,
                                      pubSubAnalytics: ICourierEventHandler?) {

        networkManagerDependencies.provideClientIdentifiers(with: identifiers,
                                                            topic: topic,
                                                            authProvider: authProvider,
                                                            pubSubAnalytics: pubSubAnalytics)
    }

    func removeAuthClientIdentifiers() {
        networkManagerDependencies.removeClientIdentifiers()
    }
}
