//
//  EventProcessorDependencies.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 03/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class EventProcessorDependencies {
    
    private let eventWarehouser: EventWarehouser
    
    private lazy var serialQueue: SerialQueue = {
        return SerialQueue(label: Constants.QueueIdentifiers.processor.rawValue)
    }()
    
    private lazy var classifier: EventClassifier = {
        return DefaultEventClassifier()
    }()
    
    init(with eventWarehouser: EventWarehouser) {
        self.eventWarehouser = eventWarehouser
    }
    
    func makeEventProcessor() -> EventProcessor {
        return DefaultEventProcessor(performOnQueue: serialQueue,
                                     classifier: classifier,
                                     eventWarehouser: eventWarehouser)
    }
}
