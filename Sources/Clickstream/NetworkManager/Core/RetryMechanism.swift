//
//  RetryMechanism.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol RetryableInputs {
    
    /// Call this function to flush eventBatches.
    /// - Parameter eventRequest: eventRequest Object to flush
    func trackBatch(with eventRequest: EventRequest)
    
    func openConnectionForcefully()
    
    /**
     Call this function to stop tracking.
    - Internally:
        * Terminates the connection.
        * Stops reachability notifier.
    */
    func stopTracking()
}

protocol RetryableOutputs {
    var isAvailble: Bool { get }
}

protocol Retryable: RetryableInputs, RetryableOutputs {}
