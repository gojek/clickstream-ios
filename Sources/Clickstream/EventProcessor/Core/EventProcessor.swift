//
//  EventProcessor.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 03/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol EventProcessorInput {
    func createEvent(event: ClickstreamEvent)
}

protocol EventProcessorOutput { }

protocol EventProcessor: EventProcessorInput, EventProcessorOutput { }

final class DefaultEventProcessor: EventProcessor {
    
    private let eventWarehouser: EventWarehouser
    private let serialQueue: SerialQueue
    private let classifier: EventClassifier
    
    init(performOnQueue: SerialQueue,
         classifier: EventClassifier,
         eventWarehouser: EventWarehouser) {
        self.serialQueue = performOnQueue
        self.classifier = classifier
        self.eventWarehouser = eventWarehouser
    }
    
    func createEvent(event: ClickstreamEvent) {
        self.serialQueue.async { [weak self] in guard let checkedSelf = self else { return }
            // Create an Event instance and forward it to the scheduler.
            if let event = checkedSelf.constructEvent(event: event) {
                checkedSelf.eventWarehouser.store(event)
            }
        }
    }
    
    private func constructEvent(event: ClickstreamEvent) -> Event? {
        
        guard let typeOfEvent = type(of: event.message).protoMessageName.components(separatedBy: ".").last?.lowercased() else { return nil }
        
        guard let classification = classifier.getClassification(eventName: type(of: event.message).protoMessageName) else {
            return nil
        }

        do {
            // Constructing the Odpf_Raccoon_Event
            let csEvent = try Odpf_Raccoon_Event.with {
                $0.eventBytes = try event.message.serializedData()
                $0.type = typeOfEvent
            }
            return try Event(guid: event.guid,
                                    timestamp: event.timeStamp,
                                    type: classification,
                                    eventProtoData: csEvent.serializedData())
        } catch {
            return nil
        }
    }
}
