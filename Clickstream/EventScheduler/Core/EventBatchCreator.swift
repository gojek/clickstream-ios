//
//  EventCreator.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 13/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol EventBatchCreatorInputs {
    
    /// Creates an EventBatch Object and forwards it to the network.
    /// - Parameter events: array of events to the sent.
    @discardableResult
    func forward(with events: [Event]) -> Bool
    
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
    
    private let networkBuilder: NetworkBuildable
    private let performOnQueue: SerialQueue
    
    init(with networkBuilder: NetworkBuildable,
         performOnQueue: SerialQueue) {
        self.networkBuilder = networkBuilder
        self.performOnQueue = performOnQueue
    }
}

extension DefaultEventBatchCreator {
    func forward(with events: [Event]) -> Bool {
        if canForward {
            let batch = EventBatch(uuid: UUID().uuidString, events: events)
                        
            networkBuilder.trackBatch(batch, completion: nil)
            return true
        }
        return false
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
