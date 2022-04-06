//
//  NetworkBuilder.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol NetworkBuildableInputs {
    
    /**
     Call this function to track an eventBatch.
        
     The EventBatch object thus received is converted to a serialised data object before forwarding to the retryMech.
     
     - parameter eventBatch: EventBatch to be forwarded.
     - parameter completion: completion callback
     */
    func trackBatch(_ eventBatch: EventBatch, completion: ((Error?)->())?)
    
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
    
    private let networkConfigs: NetworkConfigurable
    private let retryMech: Retryable
    private let performQueue: SerialQueue
    
    var isAvailable: Bool {
        return retryMech.isAvailble
    }
    
    init(networkConfigs: NetworkConfigurable,
         retryMech: Retryable,
         performOnQueue: SerialQueue) {
        self.networkConfigs = networkConfigs
        self.retryMech = retryMech
        self.performQueue = performOnQueue
    }
}

extension DefaultNetworkBuilder {
    
    func trackBatch(_ eventBatch: EventBatch, completion: ((Error?)->())?) {
        
        performQueue.async { [weak self] in guard let checkedSelf = self else { return }
            do {
                let data: Data = try eventBatch.proto.serializedData()                
                var eventRequest = EventRequest(guid: eventBatch.uuid,
                                                data: data)
                
                if eventBatch.events.first?.type == Constants.EventType.instant.rawValue {
                    eventRequest.eventType = .instant
                }
                
                checkedSelf.retryMech.trackBatch(with: eventRequest)
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
