//
//  EventSchedulerDependencies.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 13/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

/// A class that handles the dependencies pertaining to the EventScheduler Block.
final class EventSchedulerDependencies {
    
    private let networkBuildable: NetworkBuildable
    private let database: Database
    
    init(with networkBuildable: NetworkBuildable,
         db: Database) {
        self.database = db
        self.networkBuildable = networkBuildable
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
        return DefaultSchedulerService(with: Clickstream.constraints.priorities, performOnQueue: schedulerQueue)
    }()
    
    private lazy var appStateNotifier: AppStateNotifierService = {
        return DefaultAppStateNotifierService(with: schedulerQueue)
    }()
    
    private lazy var eventCreator: EventBatchCreator = {
        return DefaultEventBatchCreator(with: self.networkBuildable, performOnQueue: schedulerQueue)
    }()
    
    private lazy var eventBatchProcessor: EventBatchProcessor = {
        return DefaultEventBatchProcessor(with: eventCreator,
                                          schedulerService: schedulerService,
                                          appStateNotifier: appStateNotifier,
                                          batchSizeRegulator: batchSizeRegulator,
                                          persistence: persistence)
    }()
    
    private lazy var persistence: DefaultDatabaseDAO<Event> = {
        return DefaultDatabaseDAO<Event>(database: database,
                                         performOnQueue: daoQueue)
    }()
    
    private lazy var batchSizeRegulator: BatchSizeRegulator = {
       return DefaultBatchSizeRegulator()
    }()
    
    /// Call this method to get the EventWarehouser instance.
    /// - Returns: EventWarehouser instance.
    func makeEventWarehouser() -> EventWarehouser {
        return DefaultEventWarehouser(with: eventBatchProcessor,
                                      performOnQueue: warehouserQueue,
                                      persistence: persistence,
                                      batchSizeRegulator: batchSizeRegulator)
    }
}
