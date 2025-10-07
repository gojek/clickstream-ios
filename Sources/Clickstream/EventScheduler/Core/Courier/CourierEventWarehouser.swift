//
//  CourierEventWarehouser.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 06/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

/// A class resposible to split the event based on the type.
final class CourierEventWarehouser: EventWarehouser {
    
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

extension CourierEventWarehouser {
    
    func store(_ event: Event) {
        performQueue.async { [weak self] in guard let checkedSelf = self else { return }
            
            if event.type == Constants.EventType.instant.rawValue {
                _ = checkedSelf.eventBatchProcessor.sendInstantly(event: event)
            } else {
                if event.type != Constants.EventType.p0Event.rawValue {
                    checkedSelf.batchRegulator.observe(event)
                }
                checkedSelf.persistence.insert(event)
                if event.type == Constants.EventType.p0Event.rawValue {
                    checkedSelf.eventBatchProcessor.sendP0(classificationType: event.type)
                }
                #if EVENT_VISUALIZER_ENABLED
                /// Update the status of the event to cached
                /// to check if the delegate is connected, if not no event should be sent to client
                if let stateViewer = Clickstream._stateViewer {
                    /// Updating the event state to client to cache based on eventGuid
                    stateViewer.updateStatus(providedEventGuid: event.guid, state: .cached)
                }
                #endif
                #if TRACKER_ENABLED
                let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventCached,
                                                      eventGUID: event.guid,
                                                      eventCount: 1)
                if event.type != Constants.EventType.instant.rawValue {
                    Tracker.sharedInstance?.record(event: healthEvent)
                }
                #endif
            }
        }
    }
    
    func stop() {
        eventBatchProcessor.stop()
    }
}
