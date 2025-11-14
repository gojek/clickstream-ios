//
//  EventCreator.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 13/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol EventBatchCreatorInputs {
    associatedtype EventType: EventPersistable
    associatedtype BatchType: EventBatchPersistable where BatchType.EventType == EventType
    
    /// Creates an EventBatch Object and forwards it to the network.
    /// - Parameter events: array of events to the sent.
    @discardableResult
    func forward(with events: [EventType]) -> Bool
    
    func requestForConnection()
    
    /// Call this to stop the batch creator tasks,
    func stop()
}

protocol EventBatchCreatorOutputs {
    /// Informs whether an EventBatch can be forwarded or not.
    var canForward: Bool { get }
}

protocol EventBatchCreator: EventBatchCreatorInputs, EventBatchCreatorOutputs { }

/** The final leg in the EventScheduler block.
    This class is the interface between NetworkManager and the scheduler. Use this to forward requests to the network builder.
 */
final class DefaultEventBatchCreator: EventBatchCreator {
    typealias EventType = Event
    typealias BatchType = EventBatch
    
    private let networkBuilder: any NetworkBuildable
    private let performOnQueue: SerialQueue
    
    init(with networkBuilder: any NetworkBuildable,
         performOnQueue: SerialQueue) {
        self.networkBuilder = networkBuilder
        self.performOnQueue = performOnQueue
    }
    
    func forward(with events: [Event]) -> Bool {
        guard canForward else { return false }
        
        let batch = EventBatch(uuid: UUID().uuidString, events: events)
        networkBuilder.trackBatch(batch, completion: nil)
        
        self.trackHealthEvents(batch: batch, events: events)
        return true
    }
    
    func requestForConnection() {
        networkBuilder.openConnectionForcefully()
    }
    
    func stop() {
        networkBuilder.stopTracking()
    }
}

extension DefaultEventBatchCreator {
    var canForward: Bool {
        networkBuilder.isAvailable
    }
}

// MARK: - Track Clickstream health.
extension DefaultEventBatchCreator {
    private func trackHealthEvents(batch: EventBatch, events: [Event]) {
        #if TRACKER_ENABLED
        // We are checking only first event's type since batches are created on the basis of evemt priority i.e. realTime, healthEvent etc.
        if events.first?.type != TrackerConstant.HealthEventType && events.first?.type != Constants.EventType.instant.rawValue {
            let eventGUIDs = batch.events.map { $0.guid }
            let eventGUIDString = "\(eventGUIDs.joined(separator: ", "))"
            let batchCreatedEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchCreated,
                                                        events: eventGUIDString,
                                                        eventBatchGUID: batch.uuid)
            Tracker.sharedInstance?.record(event: batchCreatedEvent)
        }
        #endif
    }
}
