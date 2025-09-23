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
