//
//  EventBatchProcessor.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 14/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol EventBatchProcessorInputs {
    associatedtype EventType: EventPersistable
    associatedtype BatchCreatorType: EventBatchCreator where BatchCreatorType.EventType == EventType
    
    /**
        Call this to start the batch processor.
        This method triggers the schedulers and app state notifier so that the events can be triggered.
     */
    func start()
    
    /// Call this to start the batch processor and stop the tracking.
    func stop()
    
    /// Call this method to send an event directly i.e. meant for instant sending.
    /// - Parameter event: Event to be forwarded
    func sendInstantly(event: EventType) -> Bool
    
    func sendP0(classificationType: String)
}

protocol EventBatchProcessorOutputs { }

protocol EventBatchProcessor: EventBatchProcessorInputs, EventBatchProcessorOutputs { }
