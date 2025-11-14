//
//  EventProcessorDependencies.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 03/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class EventProcessorDependencies {
    
    private let socketEventWarehouser: DefaultEventWarehouser
    private let courierEventWarehouser: CourierEventWarehouser

    private let socketEventSampler: EventSampler?
    private let courierEventSampler: EventSampler?

    private lazy var socketSerialQueue: SerialQueue = {
        return SerialQueue(label: Constants.QueueIdentifiers.processor.rawValue)
    }()
    
    private lazy var courierSerialQueue: SerialQueue = {
        return SerialQueue(label: Constants.CourierQueueIdentifiers.processor.rawValue)
    }()
    
    private lazy var classifier: EventClassifier = {
        return DefaultEventClassifier()
    }()
    
    init(socketEventWarehouser: DefaultEventWarehouser,
         courierEventWarehouser: CourierEventWarehouser,
         socketEventSampler: EventSampler? = nil,
         courierEventSampler: EventSampler? = nil) {
        self.socketEventWarehouser = socketEventWarehouser
        self.courierEventWarehouser = courierEventWarehouser
        self.socketEventSampler = socketEventSampler
        self.courierEventSampler = courierEventSampler
    }

    func makeEventProcessor() -> DefaultEventProcessor {
        return DefaultEventProcessor(performOnQueue: socketSerialQueue,
                                     classifier: classifier,
                                     eventWarehouser: socketEventWarehouser,
                                     sampler: socketEventSampler)
    }

    func makeCourierEventProcessor() -> CourierEventProcessor {
        return CourierEventProcessor(performOnQueue: courierSerialQueue,
                                     classifier: classifier,
                                     eventWarehouser: courierEventWarehouser,
                                     sampler: courierEventSampler)
    }
}
