//
//  EventProcessorDependencies.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 03/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class EventProcessorDependencies {
    
    private let networkOptions: ClickstreamNetworkOptions
    private let courierEventWarehouser: CourierEventWarehouser
    
    private let courierEventSampler: EventSampler?
    
    private lazy var courierSerialQueue: SerialQueue = {
        return SerialQueue(label: Constants.CourierQueueIdentifiers.processor.rawValue)
    }()
    
    private lazy var classifier: EventClassifier = {
        return DefaultEventClassifier()
    }()
    
    private lazy var expiryManager: EventExpirationProtocol = {
        if let ttl = Clickstream.courierConfigurations.time_to_live {
            return EventExpiryManager(eventExpiryConfig: ttl)
        } else {
            return FallbackEventExpirationManager()
        }
    }()
    
    init(courierEventWarehouser: CourierEventWarehouser,
         courierEventSampler: EventSampler? = nil,
         networkOptions: ClickstreamNetworkOptions) {
        self.courierEventWarehouser = courierEventWarehouser
        self.courierEventSampler = courierEventSampler
        self.networkOptions = networkOptions
    }

    func makeCourierEventProcessor() -> CourierEventProcessor {
        return CourierEventProcessor(performOnQueue: courierSerialQueue,
                                     classifier: classifier,
                                     eventWarehouser: courierEventWarehouser,
                                     sampler: courierEventSampler,
                                     networkOptions: networkOptions, eventExpiryManager: expiryManager)
    }
}
