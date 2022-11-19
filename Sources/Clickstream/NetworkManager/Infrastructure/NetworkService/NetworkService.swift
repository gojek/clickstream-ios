//
//  NetworkService.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 23/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol NetworkServiceInputs {
    
    /// Initiates a connection through a connectable.
    /// - Parameters:
    ///   - connectionStatusListener: A callback to listen to the change in the status.
    ///   - keepTrying: allow connectable to try reconnection exponentially
    func initiateConnection(connectionStatusListener: ConnectionStatus?,
                            keepTrying: Bool)
    
    /// Writes data to the given connectable and fires a completion event after the write is completed.
    /// - Parameters:
    ///   - data:  Data to be written/sent.
    ///   - completion: A callback to listen to the result thus produced by the write action.
    func write<T: Message>(_ data: Data, completion: @escaping (Result<T, ConnectableError>) -> Void)
    
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

final class DefaultNetworkService<C: Connectable>: NetworkService {
    
    private let connectableAccessQueue = DispatchQueue(label: Constants.QueueIdentifiers.connectableAccess.rawValue,
                                                       attributes: .concurrent)
    
    /// Queue on which the action for NetworkService needs to be performed.
    private let performQueue: SerialQueue
    
    /// The supplied url request
    private var request: URLRequest
    
    /// The callback for connection status updates
    private var connectionCallback: ConnectionStatus?
    
    /// A connectable instance which the network service utilises to connect to associated network communication channel.
    private var connectable: Connectable?
    private var _connectable: Connectable? {
        get {
            connectableAccessQueue.sync {
                return connectable
            }
        }
        set {
            connectableAccessQueue.sync(flags: .barrier) { [weak self] in
                guard let checkedSelf = self else { return }
                checkedSelf.connectable = newValue
            }
        }
    }
    
    /// Initializer
    /// - Parameters:
    ///   - networkConfig: Network Configuration.
    ///   - endpoint: Endpoint to which the connectable needs to connect to.
    ///   - performOnQueue: A SerialQueue on which the networkService needs to be run.
    init(with request: URLRequest,
         performOnQueue: SerialQueue) {
        self.request = request
        self.performQueue = performOnQueue
    }
}

extension DefaultNetworkService {

    func initiateConnection(connectionStatusListener: ConnectionStatus?,
                            keepTrying: Bool = false) {
        self.connectionCallback = connectionStatusListener
        if connectable == nil {
            connectable = C(performOnQueue: performQueue)
        }
        
        connectable?.setup(request: request,
                           keepTrying: true,
                           connectionCallback: self.connectionCallback)
    }
    
    func write<T>(_ data: Data, completion: @escaping (Result<T, ConnectableError>) -> Void) where T : Message {
        performQueue.async {
            self._connectable?.write(data) { [weak self] result in guard let _ = self else { return }
                switch result {
                case .success(let response):
                    guard let responseData = response else {
                        completion(Result.failure(ConnectableError.noResponse))
                        return
                    }
                    do {
                        let result = try T(serializedData: responseData) // Deserialise the proto data.
                        completion(.success(result))
                    } catch {
                        completion(Result.failure(ConnectableError.parsingData))
                    }
                case .failure(let error):
                    #if TRACKER_ENABLED
                    if Tracker.debugMode {
                        let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamWriteToSocketFailed,
                                                              reason: error.localizedDescription)
                        Tracker.sharedInstance?.record(event: healthEvent)
                    }
                    #endif
                    completion(Result.failure(ConnectableError.networkError(error)))
                }
            }
        }
    }
    
    func terminateConnection() {
        _connectable?.disconnect()
    }
    
    func flushConnectable() {
        _connectable = nil
    }
}

extension DefaultNetworkService {
    
    var isConnected: Bool {
        _connectable?.isConnected.value ?? false
    }
}
