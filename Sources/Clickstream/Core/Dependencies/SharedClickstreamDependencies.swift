//
//  SharedClickstreamDependencies.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 03/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

/// A class equivalent to `ClickstreamDependencies.swift`
/// This class will be the main network manager dependencies, to support multiple network protocols
final class SharedClickstreamDependencies: ClickstreamDependencies {

    private let request: URLRequest
    private let database: Database
    private var networkManagerDependencies: SharedNetworkManagerDependencies!
    private let samplerConfiguration: EventSamplerConfiguration?
    private let networkOptions: ClickstreamNetworkOptions?

    var isSocketConnected: Bool {
        networkManagerDependencies.isSocketConnected
    }

    init(with request: URLRequest,
         samplerConfiguration: EventSamplerConfiguration? = nil,
         networkOptions: ClickstreamNetworkOptions? = nil) throws {

        self.request = request
        database = try DefaultDatabase(qos: .WAL)
        self.samplerConfiguration = samplerConfiguration
        self.networkOptions = networkOptions
    }

    /**
        Initializes an instance of the API with the given configurations.
        A NetworkBuildable instance. This instance acts as the only source of NetworkBuildable, 
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var networkBuilder: NetworkBuildable = {
        networkManagerDependencies = SharedNetworkManagerDependencies(with: request, db: database)
        return networkManagerDependencies.makeNetworkBuilder()
    }()

    lazy var courierNetworkBuilder: NetworkBuildable = {
        networkManagerDependencies = SharedNetworkManagerDependencies(with: request, db: database)
        return networkManagerDependencies.makeCourierNetworkBuilder()
    }()

    /** A EventWarehouser instance.
        This instance acts as the only source of EventWarehouser,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var eventWarehouser: EventWarehouser = {
        return EventSchedulerDependencies(with: networkBuilder,
                                          courierNetworkBuildable: courierNetworkBuilder,
                                          db: database).makeEventWarehouser()
    }()
    
    /**
        EventProcessor instance.
        This instance acts as the only source of EventProcessor, hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var eventProcessor: EventProcessor = {
        return EventProcessorDependencies(with: eventWarehouser, sampler: eventSampler).makeEventProcessor()
    }()

    lazy var eventSampler: EventSampler? = {
        guard let samplerConfiguration else { return nil }
        return DefaultEventSampler(config: samplerConfiguration)
    }()
}
