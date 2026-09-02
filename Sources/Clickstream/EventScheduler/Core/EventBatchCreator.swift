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
