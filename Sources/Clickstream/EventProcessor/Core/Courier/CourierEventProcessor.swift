//
//  CourierEventProcessor.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 14/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf


final class CourierEventProcessor: EventProcessor {

    private let eventWarehouser: CourierEventWarehouser
    private let serialQueue: SerialQueue
    private let classifier: EventClassifier
    private let networkOptions: ClickstreamNetworkOptions
    private var identifiers: ClickstreamClientIdentifiers?

    init(performOnQueue: SerialQueue,
         classifier: EventClassifier,
         eventWarehouser: CourierEventWarehouser,
         networkOptions: ClickstreamNetworkOptions) {
        self.serialQueue = performOnQueue
        self.classifier = classifier
        self.eventWarehouser = eventWarehouser
        self.networkOptions = networkOptions
    }
    
    func setClientIdentifiers(_ identifiers: ClickstreamClientIdentifiers?) {
        self.identifiers = identifiers
    }

    func removeClientIdentifiers() {
        identifiers = nil
    }

    func shouldTrackEvent(event: ClickstreamEvent) -> Bool {
        networkOptions.isCourierEnabled &&
        networkOptions.courierEventTypes.contains(event.messageName) &&
        identifiers != nil
    }
    
    func createEvent(event: ClickstreamEvent, isUserAuthenticated: Bool) {
        self.serialQueue.async { [weak self] in guard let checkedSelf = self else { return }
            if checkedSelf.networkOptions.courierExclusiveEventsEnabled {
                guard event.shouldTrackOnCourier(isUserLoggedIn: isUserAuthenticated, networkOptions: checkedSelf.networkOptions) else {
                    return
                }
            } else {
                guard checkedSelf.shouldTrackEvent(event: event) else {
                    return
                }
            }

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
            if let event = checkedSelf.constructEvent(event: event, isExslusive: checkedSelf.isExslusiveEvent(event)) {
                checkedSelf.eventWarehouser.store(event)
            }
        }
    }

    private func constructEvent(event: ClickstreamEvent, isExslusive: Bool) -> CourierEvent? {
        guard var typeOfEvent: String = event.eventName.components(separatedBy: ".").last?.lowercased() else { return nil }

        /// Check if appPrefix does not contain gojek
        if Clickstream.appPrefix != "" {
            typeOfEvent = Clickstream.appPrefix + "-" + typeOfEvent
        }
        
        guard let classification = classifier.getClassification(event: event) else {
            return nil
        }
        
        do {
            let csEvent = Odpf_Raccoon_Event.with {
                $0.eventBytes = event.eventData
                $0.type = typeOfEvent
                $0.eventName = event.csEventName ?? "Unknown"
                $0.product = event.product
                $0.eventTimestamp = Google_Protobuf_Timestamp(date: event.timeStamp)
                $0.isExclusive = isExslusive
            }
            return try CourierEvent(guid: event.guid,
                                    timestamp: event.timeStamp,
                                    type: classification,
                                    eventProtoData: csEvent.serializedData())
        } catch {
            return nil
        }
    }

    private func isExslusiveEvent(_ event: ClickstreamEvent) -> Bool {
        networkOptions.isWebsocketEnabled || networkOptions.courierExclusiveEventTypes.contains(event.messageName)
    }
}
