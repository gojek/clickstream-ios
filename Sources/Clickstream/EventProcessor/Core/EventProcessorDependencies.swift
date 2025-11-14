//
//  EventProcessorDependencies.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 03/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class EventProcessorDependencies {
    
    private let eventWarehouser: any EventWarehouser
    private let eventSampler: EventSampler?
    
    private lazy var serialQueue: SerialQueue = {
        return SerialQueue(label: Constants.QueueIdentifiers.processor.rawValue)
    }()
    
    private lazy var classifier: EventClassifier = {
        return DefaultEventClassifier()
    }()
    
    init(with eventWarehouser: any EventWarehouser, sampler: EventSampler? = nil) {
        self.eventWarehouser = eventWarehouser
        self.eventSampler = sampler
    }
    
    func makeEventProcessor() -> any EventProcessor {
        return DefaultEventProcessor(performOnQueue: serialQueue,
                                     classifier: classifier,
                                     eventWarehouser: eventWarehouser, sampler: eventSampler)
    }
    
    func makeCourierEventProcessor() -> any EventProcessor {
        return CourierEventProcessor(performOnQueue: serialQueue,
                                     classifier: classifier,
                                     eventWarehouser: eventWarehouser, sampler: eventSampler)
    }
}
