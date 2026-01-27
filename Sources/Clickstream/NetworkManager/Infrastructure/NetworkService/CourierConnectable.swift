//
//  CourierConnectable.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 22/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import CourierCore

protocol CourierConnectableInputs {
    
    /// Initializer
    /// - Parameters:
    ///   - performOnQueue: A queue instance on which the tasks are performed.
    ///   - userCredentials: Client's user credentials
    ///   - connectOptionsObserver: Courier Connection Observer
    ///   - pubSubAnalytics: ICourierEventHandler?
    init(config: ClickstreamCourierClientConfig,
         userCredentials: ClickstreamClientIdentifiers,
         pubSubAnalytics: ICourierEventHandler?)

    /// Publish Event Request message to Courier
    /// - Parameters:
    ///   - eventRequest: CS EventRequest
    ///   - topic: Courier's topic path
    func publishMessage(_ eventRequest: CourierEventRequest, topic: String) throws

    /// Disconnects the connection.
    func destroyAndDisconnect()
    
    /// Sets up a connectable
    /// - Parameters:
    ///   - authProvider: `IConnectionServiceProvider` instance.
    ///   - connectionCallback: A callback to update about the connection status.
    ///   - eventHandler: Courier's event handler delegate
    func setup(authProvider: IConnectionServiceProvider,
               connectionCallback: ConnectionStatus?,
               eventHandler: ICourierEventHandler)
}

protocol CourierConnectableOutputs {
    
    /// Returns the connection state.
    var isConnected: Atomic<Bool> { get }
}

protocol CourierConnectable: CourierConnectableInputs, CourierConnectableOutputs { }
