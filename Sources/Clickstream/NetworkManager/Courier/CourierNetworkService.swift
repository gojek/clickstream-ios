//
//  CourierNetworkService.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 06/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

final class CourierNetworkService<C: CourierConnectable>: NetworkService {
    
    private let connectableAccessQueue = DispatchQueue(label: Constants.QueueIdentifiers.connectableAccess.rawValue,
                                                       attributes: .concurrent)
    
    private let performQueue: SerialQueue
    private let networkConfig: NetworkConfigurable
    private var connectionCallback: ConnectionStatus?
    private var connectable: CourierConnectable?
    private var _connectable: CourierConnectable? {
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
    init(with networkConfig: NetworkConfigurable,
         performOnQueue: SerialQueue) {
        self.networkConfig = networkConfig
        self.performQueue = performOnQueue
    }

    func initiateSecondaryConnection(connectionStatusListener: ConnectionStatus?, keepTrying: Bool, identifiers: ClickstreamClientIdentifiers) async {

        guard _connectable == nil, let courierConfig = networkConfig.networkOptions?.courierConfig else { return }

        self.connectionCallback = connectionStatusListener
        _connectable = C(config: courierConfig, userCredentials: identifiers)

        await connectable?.setup(request: networkConfig.request, keepTrying: keepTrying, connectionCallback: self.connectionCallback)
    }
}

extension CourierNetworkService {
    
    func write<T>(_ data: Data, completion: @escaping (Result<T, ConnectableError>) -> Void) where T : Message {
        performQueue.async {
            do {
                try self._connectable?.publishMessage(data)
            } catch {
                // Handle failing courier message publish
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

extension CourierNetworkService {
    
    var isConnected: Bool {
        _connectable?.isConnected.value ?? false
    }
}
