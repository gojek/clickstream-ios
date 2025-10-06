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
import CourierMQTT
import CourierProtobuf

final class CourierNetworkService: NetworkService {
    
    private let connectableAccessQueue = DispatchQueue(label: Constants.QueueIdentifiers.connectableAccess.rawValue,
                                                       attributes: .concurrent)
    
    private let performQueue: SerialQueue
    private let networkConfig: NetworkConfigurable
    private var courierClient: CourierClient
    private var topic: String = "/clickstream/publish"
    private var courierCancellables: Set<CourierCore.AnyCancellable> = []
    
    private var connectionCallback: ConnectionStatus?
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
    init(with networkConfig: NetworkConfigurable, performOnQueue: SerialQueue, courierConfig: MQTTClientConfig) {
        self.networkConfig = networkConfig
        self.performQueue = performOnQueue
        self.courierClient = CourierClientFactory().makeMQTTClient(config: courierConfig)
    }
    
    private func initializeCourier(with authService: IConnectionServiceProvider) {
        let clientFactory = CourierClientFactory()
        courierClient = clientFactory.makeMQTTClient(
            config: MQTTClientConfig(
                authService: authService,
                messageAdapters: [
                    JSONMessageAdapter(),
                    ProtobufMessageAdapter()
                ],
                autoReconnectInterval: 1,
                maxAutoReconnectInterval: 30
            )
        )
    }
    
    private func subscribeTopics() {
        courierClient.subscribe((self.topic, .one))
    }
    
    private func unsubscribeTopics() {
        courierClient.unsubscribe(self.topic)
    }
}

extension CourierNetworkService {

    func initiateConnection(connectionStatusListener: ConnectionStatus?, keepTrying: Bool = false) {
        courierClient.connect()
        courierClient.connectionStatePublisher.sink { [weak self] state in
            guard let self else { return }

            if state == .connected {
                connectionCallback?(.success(.connected))
            } else if state == .disconnected {
                connectionCallback?(.success(.disconnected))
            } else if state == .connecting {
                connectionCallback?(.success(.connecting))
            } else {
                connectionCallback?(.failure(.failed))
            }
        }.store(in: &courierCancellables)
    }
    
    func write<T>(_ data: Data, completion: @escaping (Result<T, ConnectableError>) -> Void) where T : SwiftProtobuf.Message {
        performQueue.async {
            do {
                try self.courierClient.publishMessage(data, topic: self.topic, qos: .one)
                self.courierClient.messagePublisher(topic: self.topic).sink { (data: Data) in
                    // Handle response
                }.store(in: &self.courierCancellables)
            } catch {
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
    
    func terminateConnection() {
        unsubscribeTopics()
        courierClient.destroy()
        courierClient.disconnect()
    }
    
    func flushConnectable() {
        unsubscribeTopics()
        courierClient.destroy()
    }
}

extension CourierNetworkService {
    
    var isConnected: Bool {
        courierClient.connectionState == .connected
    }
}
