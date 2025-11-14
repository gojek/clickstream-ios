//
//  SharedEventSchedulerDependencies.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 13/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

/// A class that handles the dependencies pertaining to the EventScheduler Block.
final class SharedEventSchedulerDependencies {
    
    private let socketNetworkBuilder: any NetworkBuildable
    private let courierNetworkBuilder: any NetworkBuildable
    private let database: Database
    
    init(socketNetworkBuilder: any NetworkBuildable,
         courierNetworkBuilder:  any NetworkBuildable,
         db: Database) {
        self.database = db
        self.socketNetworkBuilder = socketNetworkBuilder
        self.courierNetworkBuilder = courierNetworkBuilder
    }
    
    /// A single instance of queue which ensures that all the tasks are performed on this queue.
    private let schedulerQueue = SerialQueue(label: Constants.QueueIdentifiers.scheduler.rawValue, qos: .utility)
    
    /**
     A single instance of queue which ensures that all the tasks related to warehouser are performed on this queue.
     
     The spitter is the most busy component amongst all the other components in the scheduler,
     it splits and saves to the cache so provided a separate queue to it.
     - reason - The warehouser was causing the scheduler to miss the timed deadline because of the event traffic.
    */
    private let warehouserQueue = SerialQueue(label: Constants.QueueIdentifiers.warehouser.rawValue, qos: .utility)
    
    private let daoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue,
                                       qos: .utility,
                                       attributes: .concurrent)
    
    private lazy var schedulerService: SchedulerService = {
        return DefaultSchedulerService(with: Clickstream.configurations.priorities, performOnQueue: schedulerQueue)
    }()
    
    private lazy var appStateNotifier: AppStateNotifierService = {
        return DefaultAppStateNotifierService(with: schedulerQueue)
    }()
    
    private lazy var eventCreator: DefaultEventBatchCreator = {
        return DefaultEventBatchCreator(with: socketNetworkBuilder, performOnQueue: schedulerQueue)
    }()

    private lazy var eventBatchProcessor: DefaultEventBatchProcessor = {
        return DefaultEventBatchProcessor(with: eventCreator,
                                          schedulerService: schedulerService,
                                          appStateNotifier: appStateNotifier,
                                          batchSizeRegulator: batchSizeRegulator,
                                          persistence: defaultPersistence)
    }()

    private lazy var defaultPersistence: DefaultDatabaseDAO<Event> = {
        return DefaultDatabaseDAO<Event>(database: database,
                                         performOnQueue: daoQueue)
    }()

    private lazy var batchSizeRegulator: BatchSizeRegulator = {
        return DefaultBatchSizeRegulator(userDefaultKey: "regulatedNumberOfItemsPerBatch")
    }()

    private lazy var courierEventCreator: CourierEventBatchCreator = {
        return CourierEventBatchCreator(with: courierNetworkBuilder, performOnQueue: schedulerQueue)
    }()

    private lazy var courierEventBatchProcessor: CourierEventBatchProcessor? = {
        return CourierEventBatchProcessor(with: courierEventCreator,
                                          schedulerService: schedulerService,
                                          appStateNotifier: appStateNotifier,
                                          batchSizeRegulator: courierBatchSizeRegulator,
                                          persistence: courierPersistance)
    }()

    private lazy var courierPersistance: DefaultDatabaseDAO<CourierEvent> = {
        return DefaultDatabaseDAO<CourierEvent>(database: database,
                                                performOnQueue: daoQueue)
    }()

    private lazy var courierBatchSizeRegulator: BatchSizeRegulator = {
        return DefaultBatchSizeRegulator(userDefaultKey: "regulatedNumberOfItemsPerBatchCourier")
    }()

    /// Call this method to get the SharedEventWarehouser instance.
    /// - Parameter networkOptions: EventWarehouser instance.
    /// - Returns: CS networking options
    func makeSharedEventWarehouser(with networkOptions: ClickstreamNetworkOptions) -> EventWarehouser {
        SharedEventWarehouser(performOnQueue: warehouserQueue,
                              socketPersistance: defaultPersistence,
                              courierPersistance: courierPersistance,
                              socketBatchProcessor: eventBatchProcessor,
                              courierBatchProcessor: courierEventBatchProcessor,
                              socketBatchSizeRegulator: batchSizeRegulator,
                              courierBatchSizeRegulator: courierBatchSizeRegulator,
                              networkOptions: networkOptions)
    }
}
