//
//  CourierConnectable.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 22/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import Combine
import CourierCore

protocol CourierConnectableInputs {
    
    /// Initializer
    /// - Parameters:
    ///   - performOnQueue: A queue instance on which the tasks are performed.
    init(config: ClickstreamCourierConfig, userCredentials: ClickstreamClientIdentifiers)
    
    
    /// Writes data to the stream.
    /// - Parameters:
    ///   - data: Data to be written/sent.
    ///   - completion: A callback when the data gets written successfully or fails.
    func publishMessage(_ data: Data) throws

    /// Disconnects the connection.
    func disconnect()
    
    /// Sets up a connectable
    /// - Parameters:
    ///   - request: URLRequest which the connectable must connect to.
    ///   - keepTrying: A control flag which tells the connectable to keep trying till the connection is not established.
    ///   - connectionCallback: A callback to update about the connection status.
    ///   - config: A courier configurations
    ///   - userCredentials: A User's credentials
    func setup(request: URLRequest, keepTrying: Bool, connectionCallback: ConnectionStatus?) async
}

protocol CourierConnectableOutputs {
    
    /// Returns the connection state.
    var isConnected: Atomic<Bool> { get }
}

protocol CourierConnectable: CourierConnectableInputs, CourierConnectableOutputs { }
