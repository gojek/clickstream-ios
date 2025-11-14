//
//  NetworkBuilder.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol NetworkBuildableInputs {
    associatedtype BatchType: EventBatchPersistable
    
    /**
     Call this function to track an eventBatch.
        
     The EventBatch object thus received is converted to a serialised data object before forwarding to the retryMech.
     
     - parameter eventBatch: EventBatch to be forwarded.
     - parameter completion: completion callback
     */
    func trackBatch<T: EventBatchPersistable>(_ eventBatch: T, completion: ((_ error: Error?) -> Void)?)
    
    func openConnectionForcefully()
    
    /// Call this function to stop tracking. The request to stop is routed through retry mechanism.
    func stopTracking()
}

protocol NetworkBuildableOutputs {
    var isAvailable: Bool { get }
}

protocol NetworkBuildable: NetworkBuildableInputs, NetworkBuildableOutputs { }

/// This is the class which the scheduler will communicate with in order to get the network related tasks done
final class DefaultNetworkBuilder: NetworkBuildable {
    typealias BatchType = EventBatch
    
    private let networkConfigs: NetworkConfigurable
    private let retryMech: DefaultRetryMechanism
    private let performQueue: SerialQueue
    
    var isAvailable: Bool {
        return retryMech.isAvailble
    }
    
    init(networkConfigs: NetworkConfigurable,
         retryMech: DefaultRetryMechanism,
         performOnQueue: SerialQueue) {
        self.networkConfigs = networkConfigs
        self.retryMech = retryMech
        self.performQueue = performOnQueue
    }
}

extension DefaultNetworkBuilder {
    
    func trackBatch<T: EventBatchPersistable>(_ eventBatch: T, completion: ((_ error: Error?) -> Void)?) {

        performQueue.async { [weak self] in guard let checkedSelf = self else { return }
            do {
                let data: Data = try eventBatch.proto.serializedData()
                print("NetworkBuilder, trackedBatch with id: \(eventBatch.uuid) and itemsCount: \(eventBatch.events.count)")
                var eventRequest = EventRequest(guid: eventBatch.uuid,
                                                data: data)
                
                if eventBatch.events.first?.type == Constants.HealthEventType {
                    eventRequest.eventType = .internalEvent
                } else if eventBatch.events.first?.type == Constants.EventType.instant.rawValue {
                    eventRequest.eventType = .instant
                } else {
                    checkedSelf.trackHealthEvents(eventBatch: eventBatch,
                                                          eventBatchData: data)
                }
                eventRequest.eventCount = eventBatch.events.count
                checkedSelf.retryMech.trackBatch(with: eventRequest)
                #if EVENT_VISUALIZER_ENABLED
                /// Update status of the event batch to sent to network
                /// to check if the delegate is connected, if not no event should be sent to client
                if let stateViewer = Clickstream._stateViewer {
                    for event in eventBatch.events {
                        /// Updating the event state to sent based on eventGuid.
                        /// Also eventBatchID is also sent which would be used later to map these events and
                        /// then update the state to acknowledged.
                        stateViewer.updateStatus(providedEventGuid: event.guid, eventBatchID: eventBatch.uuid, state: .sent)
                    }
                }
                #endif
                completion?(nil)
            } catch {
                print("There was an error from the Network builder. Description: \(error)",.critical)
                completion?(error)
            }
        }
    }
    
    func openConnectionForcefully() {
        retryMech.openConnectionForcefully()
    }
    
    func stopTracking() {
        performQueue.async { [weak self] in guard let checkedSelf = self else { return }
            checkedSelf.retryMech.stopTracking()
        }
    }
}

// MARK: - Track Clickstream health.
extension DefaultNetworkBuilder {
    private func trackHealthEvents<T: EventBatchPersistable>(eventBatch: T, eventBatchData: Data) {
        #if TRACKER_ENABLED
        guard Tracker.debugMode else { return }
        let eventGUIDs: [String] = eventBatch.events.compactMap { $0.guid }
        let eventGUIDsString = "\(eventGUIDs.joined(separator: ", "))"
        
        let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamBatchSent,
                                              events: eventGUIDsString,
                                              eventBatchGUID: eventBatch.uuid, 
                                              eventCount: eventBatch.events.count)
        Tracker.sharedInstance?.record(event: healthEvent)
        #endif
    }
}
