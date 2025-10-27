//
//  CourierNetworkService.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 06/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf
import CourierCore

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
    
    func write<T>(_ data: Data, completion: @escaping (Result<T, ConnectableError>) -> Void) where T : SwiftProtobuf.Message {
        performQueue.async {
            do {
                try self._connectable?.publishMessage(data)
            } catch(let error) {
                // Handle failing courier message publish
                completion(.failure(ConnectableError.networkError(error)))
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

extension CourierNetworkService {
    func executeHTTPRequest() async throws -> Odpf_Raccoon_EventResponse {
        do {
            let session = URLSession.shared
            let (data, response) = try await session.data(for: self.networkConfig.request)

            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                throw CourierError.httpError
            }

            // Decode protobuf (or other data format)
            let eventResponse = try Odpf_Raccoon_EventResponse(serializedBytes: data)
            return eventResponse
        } catch let error as URLError {
            throw ConnectableError.networkError(error)
        } catch let error as Swift.DecodingError {
            throw ConnectableError.networkError(error)
        } catch {
            throw CourierError.otherError
        }
    }
}
