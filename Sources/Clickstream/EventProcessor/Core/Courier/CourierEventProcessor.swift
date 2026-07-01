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
    private let sampler: EventSampler?
    private let networkOptions: ClickstreamNetworkOptions
    private let eventExpirationManager: EventExpirationProtocol

    init(performOnQueue: SerialQueue,
         classifier: EventClassifier,
         eventWarehouser: CourierEventWarehouser,
         sampler: EventSampler?,
         networkOptions: ClickstreamNetworkOptions,
         eventExpiryManager: EventExpirationProtocol) {
        self.serialQueue = performOnQueue
        self.classifier = classifier
        self.eventWarehouser = eventWarehouser
        self.sampler = sampler
        self.networkOptions = networkOptions
        self.eventExpirationManager = eventExpiryManager
    }

    func shouldTrackEvent(event: ClickstreamEvent) -> Bool {
        networkOptions.courierEventTypes.contains(event.messageName)
    }

    func sampleEvent(event: ClickstreamEvent) -> Bool {
        if let eventSampler = sampler {
            return eventSampler.shouldTrack(event: event)
        }
        return true
    }
    
    func createEvent(event: ClickstreamEvent, isUserAuthenticated: Bool) {
        self.serialQueue.async { [weak self] in guard let checkedSelf = self else { return }
            guard checkedSelf.sampleEvent(event: event) else {
                return
            }
            
            #if TRACKER_ENABLED
            if Tracker.debugMode {
                let isCourierWhitelisted = checkedSelf.networkOptions.courierEventTypes.contains(event.messageName)
                if isCourierWhitelisted {
                    checkedSelf.trackHealthEvent(event: event, healthEventName: .Courier_ClickstreamEventReceived, reason: "Event Received by SDK")
                }
            }
            #endif
            guard event.shouldTrackOnCourier(isUserLoggedIn: isUserAuthenticated, networkOptions: checkedSelf.networkOptions) else {
                #if TRACKER_ENABLED
                if Tracker.debugMode {
                    let isCourierWhitelisted = checkedSelf.networkOptions.courierEventTypes.contains(event.messageName)
                    if isCourierWhitelisted {
                        checkedSelf.trackHealthEvent(event: event, healthEventName: .Courier_ClickstreamEventNotCached, reason: "shouldTrackOnCourier is false with networkoptions: \(checkedSelf.networkOptions)")
                    }
                }
                #endif
                return
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

        let resolved = resolveClassification(for: event,
                                             legacy: classification,
                                             defaultExpiry: eventExpirationManager.getExpiration(for: event))
        
        do {
            let csEvent = Odpf_Raccoon_Event.with {
                $0.eventBytes = event.eventData
                $0.type = typeOfEvent
                $0.eventName = event.csEventName ?? "Unknown"
                $0.product = event.product
                $0.eventTimestamp = Google_Protobuf_Timestamp(date: event.timeStamp)
                $0.isExclusive = isExslusive
                $0.appVersion = Clickstream.appVersion
                $0.platform = .ios
            }
            return try CourierEvent(guid: event.guid,
                                    timestamp: event.timeStamp,
                                    type: resolved.type,
                                    eventProtoData: csEvent.serializedData(), expiryTime: resolved.expiry)
        } catch {
            return nil
        }
    }

    /// Resolves the routing `type` and expiry for an event.
    ///
    /// When classification is disabled the legacy classification and expiry are returned unchanged.
    /// When enabled, instant and P0 events keep their legacy routing (preserving the current fast
    /// paths); all other events are routed by their resolved classification id and expire per the
    /// classification's TTL.
    private func resolveClassification(for event: ClickstreamEvent,
                                       legacy: String,
                                       defaultExpiry: Date) -> (type: String, expiry: Date) {
        guard Clickstream.isClassificationEnabled, let properties = Clickstream.classificationConfig else {
            return (legacy, defaultExpiry)
        }

        if legacy == Constants.EventType.instant.rawValue || legacy == Constants.EventType.p0Event.rawValue {
            return (legacy, defaultExpiry)
        }

        let classificationId = properties.resolveClassificationId(protoName: event.messageName,
                                                                  eventName: event.eventName,
                                                                  csEventName: event.csEventName)
        if let config = properties.configs.first(where: { $0.classificationId == classificationId }) {
            return (classificationId, config.expiryDate(from: event.timeStamp))
        }
        return (classificationId, defaultExpiry)
    }

    private func isExslusiveEvent(_ event: ClickstreamEvent) -> Bool {
        !networkOptions.isWebsocketEnabled || networkOptions.courierExclusiveEventTypes.contains(event.messageName)
    }

    func createBinaryEvent(event: CSBinaryEvent) {
        self.serialQueue.async { [weak self] in
            guard let checkedSelf = self else { return }
            if let eventToStore = checkedSelf.constructBinaryEvent(event: event) {
                checkedSelf.eventWarehouser.store(eventToStore)
            }
        }
    }

    private func constructBinaryEvent(event: CSBinaryEvent) -> CourierEvent? {
        let placeholder = ClickstreamEvent(
            guid: event.guid,
            timeStamp: event.timestamp,
            message: nil,
            eventName: event.eventName,
            eventData: Data(),
            product: event.product ?? ""
        )
        guard let classification = classifier.getClassification(event: placeholder) else { return nil }
        guard let decodedData = Data(base64Encoded: event.encodedData) else { return nil }

        do {
            let csEvent = Odpf_Raccoon_Event.with {
                $0.eventBytes = decodedData
                $0.type = event.type.lowercased()
                $0.eventName = event.eventName
                $0.product = event.product ?? ""
                $0.eventTimestamp = Google_Protobuf_Timestamp(date: event.timestamp)
                $0.isExclusive = true
                $0.appVersion = Clickstream.appVersion
                $0.platform = .ios
            }
            return try CourierEvent(
                guid: event.guid,
                timestamp: event.timestamp,
                type: classification,
                eventProtoData: csEvent.serializedData(),
                expiryTime:  Date()
            )
        } catch {
            return nil
        }
    }
    
    private func trackHealthEvent(event: ClickstreamEvent, healthEventName: HealthEvents, reason: String) {
        if let classification = self.classifier.getClassification(event: event), classification == "realTime" {
            let healthEvent = HealthAnalysisEvent(eventName: healthEventName, eventGUID: event.guid, reason: reason, eventCount: 1)
            Tracker.sharedInstance?.record(event: healthEvent)
        }
    }
}
