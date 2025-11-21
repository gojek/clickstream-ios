//
//  ClickstreamDependencies.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

/// A class that generates all the dependencies of the Clickstream SDK.
final class DefaultClickstreamDependencies {
    
    private let request: URLRequest
    private let database: Database
    private var networkManagerDependencies: NetworkManagerDependencies!

    private let samplerConfiguration: EventSamplerConfiguration?

    private let networkOptions: ClickstreamNetworkOptions
    
    var isSocketConnected: Bool {
        networkManagerDependencies.isSocketConnected
    }

    var isCourierConnected: Bool {
        networkManagerDependencies.isCourierConnected
    }

    init(with request: URLRequest,
         samplerConfiguration: EventSamplerConfiguration? = nil,
         networkOptions: ClickstreamNetworkOptions) throws {

        self.request = request
        self.samplerConfiguration = samplerConfiguration
        self.networkOptions = networkOptions

        let db = try DefaultDatabase(qos: .WAL)
        database = db
        networkManagerDependencies = NetworkManagerDependencies(with: request, db: db, networkOptions: networkOptions)
    }

    /**
        Initializes an instance of the API with the given configurations.
        A NetworkBuildable instance. This instance acts as the only source of NetworkBuildable,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var socketNetworkBuilder: any NetworkBuildable = {
         networkManagerDependencies.makeNetworkBuilder()
    }()

    lazy var courierNetworkBuilder: any NetworkBuildable = {
         networkManagerDependencies.makeCourierNetworkBuilder()
    }()

    /** A EventWarehouser instance.
        This instance acts as the only source of EventWarehouser,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var socketEventWarehouser: DefaultEventWarehouser = {
        EventSchedulerDependencies(
            socketNetworkBuider: socketNetworkBuilder,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        ).makeEventWarehouser()
    }()

    lazy var courierEventWarehouser: CourierEventWarehouser = {
        EventSchedulerDependencies(
            socketNetworkBuider: socketNetworkBuilder,
            courierNetworkBuider: courierNetworkBuilder,
            db: database,
            networkOptions: networkOptions
        ).makeCourierEventWarehouser()
    }()

    /**
        EventProcessor instance.
        This instance acts as the only source of EventProcessor, hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var socketEventProcessor: DefaultEventProcessor = {
        EventProcessorDependencies(
            socketEventWarehouser: socketEventWarehouser,
            courierEventWarehouser: courierEventWarehouser,
            socketEventSampler: socketEventSampler,
            networkOptions: networkOptions,
        ).makeEventProcessor()
    }()
    
    lazy var courierEventProcessor: CourierEventProcessor = {
        EventProcessorDependencies(
            socketEventWarehouser: socketEventWarehouser,
            courierEventWarehouser: courierEventWarehouser,
            socketEventSampler: socketEventSampler,
            networkOptions: networkOptions,
        ).makeCourierEventProcessor()
    }()

    lazy var socketEventSampler: EventSampler? = {
        guard let samplerConfiguration else { return nil }
        return DefaultEventSampler(config: samplerConfiguration)
    }()
}

extension DefaultClickstreamDependencies {

    /// Courier client's user credentials provider
    /// - Parameter identifiers: Client's user identifiers
    /// - Parameter topic: Courier's topic path
    func provideCourierClientIdentifiers(with identifiers: ClickstreamClientIdentifiers, topic: String) {
        courierEventProcessor.setClientIdentifiers(identifiers)
        networkManagerDependencies.provideClientIdentifiers(with: identifiers, topic: topic)
    }

    /// Remove client identifier upon user's session is revoked
    public func removeCourierClientIdentifiers() {
        courierEventProcessor.removeClientIdentifiers()
        networkManagerDependencies.removeClientIdentifiers()
    }
}
