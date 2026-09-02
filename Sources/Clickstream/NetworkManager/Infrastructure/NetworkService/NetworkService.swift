//
//  NetworkService.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 23/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import CourierCore

protocol NetworkServiceInputs {
    
    /// Initiates a Courier connection through a connectable.
    /// - Parameters:
    ///   - connectionStatusListener: A callback to listen to the change in the status.
    ///   - userCredentials: Courier's user credentials
    ///   - authProvider: Courier's user credentials
    ///   - eventHandler: Courier's event handler delegate
    ///   - isForced: Connection forceable flag
    func initiateCourierConnection(connectionStatusListener: ConnectionStatus?,
                                   identifiers: ClickstreamClientIdentifiers,
                                   authProvider: IConnectionServiceProvider,
                                   eventHandler: ICourierEventHandler,
                                   pubSubAnalytics: ICourierEventHandler?,
                                   isForced: Bool)
    
    /// Terminates the established connection.
    func terminateConnection()
    
    /// Flushes connectable
    func flushConnectable()
}

protocol NetworkServiceOutputs {
    
    /// Returns the state of the connection.
    var isConnected: Bool { get }
}

protocol NetworkService: NetworkServiceInputs, NetworkServiceOutputs { }
