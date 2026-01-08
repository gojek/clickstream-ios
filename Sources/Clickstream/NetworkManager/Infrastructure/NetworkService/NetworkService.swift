//
//  NetworkService.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 23/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import CourierCore
import SwiftProtobuf

protocol NetworkServiceInputs {
    
    /// Initiates a connection through a connectable.
    /// - Parameters:
    ///   - connectionStatusListener: A callback to listen to the change in the status.
    ///   - keepTrying: allow connectable to try reconnection exponentially
    func initiateWebsocketConnection(connectionStatusListener: ConnectionStatus?, keepTrying: Bool)

    
    /// Initiates a Courier connection through a connectable.
    /// - Parameters:
    ///   - connectionStatusListener: A callback to listen to the change in the status.
    ///   - userCredentials: Courier's user credentials
    ///   - eventHandler: Courier's event handler delegate
    ///   - isForced: Connection forceable flag
    func initiateCourierConnection(connectionStatusListener: ConnectionStatus?,
                                   identifiers: ClickstreamClientIdentifiers,
                                   eventHandler: ICourierEventHandler,
                                   isForced: Bool) async

    /// Writes data to the given connectable and fires a completion event after the write is completed.
    /// - Parameters:
    ///   - data:  Data to be written/sent.
    ///   - completion: A callback to listen to the result thus produced by the write action.
    func write<T: SwiftProtobuf.Message>(_ data: Data, completion: @escaping (Result<T, ConnectableError>) -> Void)
    
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

extension NetworkService {
    func initiateWebsocketConnection(connectionStatusListener: ConnectionStatus?, keepTrying: Bool) {}
    func initiateCourierConnection(connectionStatusListener: ConnectionStatus?,
                                   identifiers: ClickstreamClientIdentifiers,
                                   eventHandler: ICourierEventHandler,
                                   isForced: Bool) async {}
    func write<T: SwiftProtobuf.Message>(_ data: Data, completion: @escaping (Result<T, ConnectableError>) -> Void) {}
}
