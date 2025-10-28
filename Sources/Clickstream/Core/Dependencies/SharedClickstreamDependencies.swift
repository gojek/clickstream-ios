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
    private let samplerConfiguration: EventSamplerConfiguration?
    private let networkOptions: ClickstreamNetworkOptions

    var isSocketConnected: Bool {
        networkManagerDependencies.isSocketConnected
    }

    init(with request: URLRequest,
         samplerConfiguration: EventSamplerConfiguration? = nil,
         networkOptions: ClickstreamNetworkOptions) throws {

        self.request = request
        database = try DefaultDatabase(qos: .WAL)
        self.samplerConfiguration = samplerConfiguration
        self.networkOptions = networkOptions
    }

    /**
        Initializes an instance of `SharedNetworkManagerDependencies`
        Given `URLRequest`, `Database`, & `ClickstreamNetworkOptions`
     */
    lazy var networkManagerDependencies: SharedNetworkManagerDependencies = {
        return SharedNetworkManagerDependencies(with: request,
                                                db: database,
                                                networkOptions: networkOptions)
    }()

    /**
        Initializes an instance of the API with the given configurations.
        A NetworkBuildable instance. This instance acts as the only source of NetworkBuildable, 
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var networkBuilder: NetworkBuildable = {
        return networkManagerDependencies.makeNetworkBuilder()
    }()

    /**
        Initializes an instance of the API with the given configurations.
        A NetworkBuildable instance. This instance acts as the only source of Courier's NetworkBuildable,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var secondaryNetworkBuilder: NetworkBuildable = {
        return networkManagerDependencies.makeCourierNetworkBuilder()
    }()

    /** A EventWarehouser instance.
        This instance acts as the only source of EventWarehouser,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var eventWarehouser: EventWarehouser = {
        EventSchedulerDependencies(
            with: networkBuilder,
            secondary: secondaryNetworkBuilder,
            db: database
        ).makeSharedEventWarehouser(with: networkOptions)
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

extension SharedClickstreamDependencies {

    /// Courier client's user credentials provider
    /// - Parameter userCredentials: A user credentials object
    func provideClientIdentifiers(with identifiers: ClickstreamClientIdentifiers) {
        guard networkOptions.isCourierEnabled, !networkOptions.courierEventTypes.isEmpty else {
            return
        }
        networkManagerDependencies.provideClientIdentifiers(with: identifiers)
    }
}
