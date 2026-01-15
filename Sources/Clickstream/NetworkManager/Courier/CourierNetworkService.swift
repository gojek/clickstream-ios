//
//  CourierNetworkService.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 06/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf
import Combine
import CourierCore

final class CourierNetworkService<C: CourierConnectable>: NetworkService {
    
    private let connectableAccessQueue = DispatchQueue(label: Constants.CourierQueueIdentifiers.connectableAccess.rawValue,
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
    
    private var connectionOptions: ConnectOptions?
    private var connectOptionsProvider: CourierConnectOptionsObserver?
    
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

    /// Initiate secondary network connection given `Connectable`
    /// - Parameters:
    ///   - connectionStatusListener: A callback connection listerner
    ///   - keepTrying: A flag to rery connect attempts
    ///   - identifiers: Client's user identifiers
    func initiateCourierConnection(connectionStatusListener: ConnectionStatus?,
                                   identifiers: ClickstreamClientIdentifiers,
                                   eventHandler: ICourierEventHandler,
                                   connectOptionsObserver: CourierConnectOptionsObserver?,
                                   isForced: Bool) async {

        if isForced {
            _connectable = nil
        }

        guard _connectable == nil, let courierConfig = networkConfig.networkOptions?.courierConfig else {
            return
        }

        self.connectionCallback = connectionStatusListener
        _connectable = C(config: courierConfig,
                         userCredentials: identifiers,
                         connectOptionsObserver: connectOptionsObserver)

        await connectable?.setup(request: networkConfig.request,
                                 connectionCallback: self.connectionCallback,
                                 eventHandler: eventHandler)
    }
}

extension CourierNetworkService {
    
    func publish(_ eventRequest: CourierEventRequest, topic: String) async throws {
        try await _connectable?.publishMessage(eventRequest, topic: topic)
    }
    
    func terminateConnection() {
        _connectable?.destroyAndDisconnect()
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

    func executeHTTPRequest(_ eventRequest: CourierEventRequest) async throws -> Odpf_Raccoon_EventResponse {
        guard _connectable is DefaultCourierHandler else {
            throw ConnectableError.failed
        }

        do {
            let session = URLSession.shared
            var request = self.networkConfig.request
            request.httpMethod = "POST"
            request.setValue("application/proto", forHTTPHeaderField: "Content-Type")

            guard let eventRequestData = eventRequest.data else {
                throw ConnectableError.parsingData
            }

            var requestProto = try Odpf_Raccoon_EventRequest(serializedBytes: eventRequestData)
            requestProto.sentTime = Google_Protobuf_Timestamp(date: Date())
            request.httpBody = try requestProto.serializedData()

            let (data, response) = try await session.data(for: request)

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
