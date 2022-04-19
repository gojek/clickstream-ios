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
    
    private let database: Database
    private let networkConfigurations: NetworkConfigurations
    
    init(with networkConfigurations: NetworkConfigurations) throws {
        self.networkConfigurations = networkConfigurations
        database = try DefaultDatabase(qos: .WAL)
    }
    
    /**
        Initializes an instance of the API with the given configurations.
        A NetworkBuildable instance. This instance acts as the only source of NetworkBuildable,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var networkBuilder: NetworkBuildable = {
        return NetworkManagerDependencies(with: networkConfigurations,
                                          db: database).makeNetworkBuilder()
    }()
    
    /** A EventWarehouser instance.
        This instance acts as the only source of EventWarehouser,
        hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var eventWarehouser: EventWarehouser = {
        return EventSchedulerDependencies(with: networkBuilder,
                                          db: database).makeEventWarehouser()
    }()
    
    /**
        EventProcessor instance.
        This instance acts as the only source of EventProcessor, hence ensuring only one instane is tied to the Clickstream class.
     */
    lazy var eventProcessor: EventProcessor = {
        return EventProcessorDependencies(with: eventWarehouser).makeEventProcessor()
    }()
}
