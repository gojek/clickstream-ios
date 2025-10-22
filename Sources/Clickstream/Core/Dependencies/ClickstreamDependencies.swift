//
//  ClickstreamDependencies.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol ClickstreamDependencies {
    var isSocketConnected: Bool { get }
    var networkBuilder: NetworkBuildable { get }
    var eventWarehouser: EventWarehouser { get }
    var eventProcessor: EventProcessor { get }
    var eventSampler: EventSampler? { get }
}

/// A class that generates all the dependencies of the Clickstream SDK.
final class DefaultClickstreamDependencies: ClickstreamDependencies {
    
    private let request: URLRequest
    private let database: Database
    private var networkManagerDependencies: NetworkManagerDependencies!
    private let samplerConfiguration: EventSamplerConfiguration?
    
    var isSocketConnected: Bool {
        networkManagerDependencies.isSocketConnected
    }

    init(with request: URLRequest, samplerConfiguration: EventSamplerConfiguration? = nil) throws {
        self.request = request
        self.samplerConfiguration = samplerConfiguration
        database = try DefaultDatabase(qos: .WAL)
    }
    
    /**
        Initializes an instance of the API with the given configurations.
        A NetworkBuildable instance. This instance acts as the only source of NetworkBuildable,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var networkBuilder: NetworkBuildable = {
        networkManagerDependencies = NetworkManagerDependencies(with: request,
                                                                db: database)
        return networkManagerDependencies.makeNetworkBuilder()
    }()
    
    /** A EventWarehouser instance.
        This instance acts as the only source of EventWarehouser,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var eventWarehouser: EventWarehouser = {
        return EventSchedulerDependencies(with: networkBuilder,
                                          db: database).makeEventWarehouser()
    }()
    
    lazy var eventSampler: EventSampler? = {
        guard let samplerConfiguration else { return nil }
        return DefaultEventSampler(config: samplerConfiguration)
    }()
    
    /**
        EventProcessor instance.
        This instance acts as the only source of EventProcessor, hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var eventProcessor: EventProcessor = {
        return EventProcessorDependencies(with: eventWarehouser, sampler: eventSampler).makeEventProcessor()
    }()
}
