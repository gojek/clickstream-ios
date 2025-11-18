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
    
    private let eventWarehouser: DefaultEventWarehouser
    private let serialQueue: SerialQueue
    private let classifier: EventClassifier
    private let sampler: EventSampler?
    
    init(performOnQueue: SerialQueue,
         classifier: EventClassifier,
         eventWarehouser: DefaultEventWarehouser,
         sampler: EventSampler? = nil) {
        self.serialQueue = performOnQueue
        self.classifier = classifier
        self.eventWarehouser = eventWarehouser
        self.sampler = sampler
    }
    
    func shouldTrackEvent(event: ClickstreamEvent) -> Bool {
        if let eventSampler = sampler {
            return eventSampler.shouldTrack(event: event)
        }
        return true
    }
    
    func createEvent(event: ClickstreamEvent) {
        self.serialQueue.async { [weak self] in guard let checkedSelf = self else { return }
            if checkedSelf.shouldTrackEvent(event: event) {

                #if EVENT_VISUALIZER_ENABLED
                /// Sent event data to client with state received
                /// to check if the delegate is connected, if not no event should be sent to client
                if let message = event.message, let stateViewer = Clickstream._stateViewer {
                    /// creating the EventData object and setting the status to received.
                    let eventsData = EventData(msg: message, state: .received)
                    /// Sending the eventData object to client
                    stateViewer.sendEvent(eventsData)
                }
                #endif
                // Create an Event instance and forward it to the scheduler.
                    if let event = checkedSelf.constructEvent(event: event) {
                        checkedSelf.eventWarehouser.store(event)
                    }
            }
        }
    }
    
    private func constructEvent(event: ClickstreamEvent) -> Event? {
        
        guard var typeOfEvent: String = event.eventName.components(separatedBy: ".").last?.lowercased() else { return nil }
        /// Check if appPrefix does not contain gojek
        if Clickstream.appPrefix != "" {
            typeOfEvent = Clickstream.appPrefix + "-" + typeOfEvent
        }

        
        guard let classification = classifier.getClassification(event: event) else {
            return nil
        }
        
        do {
            // Constructing the Odpf_Raccoon_Event
            let csEvent = Odpf_Raccoon_Event.with {
                $0.eventBytes = event.eventData
                $0.type = typeOfEvent
                $0.eventName = event.eventName
                $0.product = event.product
                $0.eventTimestamp = Google_Protobuf_Timestamp(date: event.timeStamp)
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
