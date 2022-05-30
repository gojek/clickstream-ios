//
//  Connectable.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 27/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

typealias ConnectionStatus = (Result<ConnectableState, ConnectableError>) -> ()

enum ConnectableState {
    case connected
    case disconnected
    case connecting
    case cancelled
}

enum ConnectableError: Error {
    case networkError(Error)
    case failed
    case malformedPath
    case noResponse
    case parsingData
}

enum ConnectableEvent { // A copy of the WebSocketEvent
    case connected([String: String])
    case disconnected(String, UInt16)
    case text(String)
    case binary(Data)
    case pong(Data?)
    case ping(Data?)
    case error(Error?)
    case viabilityChanged(Bool)
    case reconnectSuggested(Bool)
    case cancelled
}

protocol ConnectableInputs {
    
    /// Initializer
    /// - Parameters:
    ///   - request: URLRequest which the connectable must connect to.
    ///   - keepTrying: A control flag which tells the connectable to keep trying till the connection is not established.
    ///   - performOnQueue: A queue instance on which the tasks are performed.
    ///   - connectionCallback: A callback to update about the connection status.
    init(request: URLRequest, keepTrying: Bool, performOnQueue: SerialQueue, connectionCallback: ConnectionStatus?)
    
    
    /// Writes data to the stream.
    /// - Parameters:
    ///   - data: Data to be written/sent.
    ///   - completion: A callback when the data gets written successfully or fails.
    func write(_ data: Data, completion: @escaping ((Result<Data?, ConnectableError>) -> Void))
    
    /// Disconnects the connection.
    func disconnect()
    
    //    func connect(with request: URLRequest, _ completion: @escaping ((Result<[String: String]?, ConnectionError>) -> Void))
}

protocol ConnectableOutputs {
    
    /// Returns the connection state.
    var isConnected: Bool { get }
}

protocol Connectable: ConnectableInputs, ConnectableOutputs { }
