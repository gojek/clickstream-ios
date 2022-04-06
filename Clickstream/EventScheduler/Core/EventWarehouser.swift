//
//  EventWarehouser.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 28/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol EventWarehouser {
    
    /// Call this to schedule an event.
    /// - Parameter event: event object
    func store(_ event: Event)
    
    /// Call this to stop the scheduler tasks. Meant to be called only when you need to stop tasks and purge resources.
    func stop()
}

/// A class resposible to split the event based on the type. 
final class DefaultEventWarehouser: EventWarehouser {
    
    private let performQueue: SerialQueue
    private let eventBatchProcessor: EventBatchProcessor
    private let persistence: DefaultDatabaseDAO<Event>
    private let batchRegulator: BatchSizeRegulator
    
    init(with eventBatchProcessor: EventBatchProcessor,
         performOnQueue: SerialQueue,
         persistence: DefaultDatabaseDAO<Event>,
         batchSizeRegulator: BatchSizeRegulator) {
        self.eventBatchProcessor = eventBatchProcessor
        self.performQueue = performOnQueue
        self.persistence = persistence
        self.batchRegulator = batchSizeRegulator
        start()
    }
    
    /// This method starts the event batch processor.
    private func start() {
        self.eventBatchProcessor.start()
    }
}

extension DefaultEventWarehouser {
    
    func store(_ event: Event) {
        performQueue.async { [weak self] in guard let checkedSelf = self else { return }
            
            if event.type == Constants.EventType.instant.rawValue {
                _ = checkedSelf.eventBatchProcessor.sendInstantly(event: event)
            } else {
                checkedSelf.batchRegulator.observe(event)
                checkedSelf.persistence.insert(event)
            }
        }
    }
    
    func stop() {
        eventBatchProcessor.stop()
    }
}
