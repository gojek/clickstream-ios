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
    private var courierClient: CourierClient?
    private let courierConfig: ClickstreamCourierConfig
    private var courierCancellables: Set<CourierCore.AnyCancellable> = []
    private var messagePublisher: AnyPublisher<CourierCore.Message, Never>?
    
    private lazy var topics: [String: QoS] = {
        courierConfig.topics.compactMapValues { QoS(value: $0) }
    }()
    
    private var currentTopic: String {
        topics.first?.key ?? ""
    }
    
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

    var isConnected: Bool {
        courierClient?.connectionState == .connected
    }

    /// Initializer
    /// - Parameters:
    ///   - networkConfig: Network Configuration.
    ///   - endpoint: Endpoint to which the connectable needs to connect to.
    ///   - performOnQueue: A SerialQueue on which the networkService needs to be run.
    init(with networkConfig: NetworkConfigurable, performOnQueue: SerialQueue, courierConfig: ClickstreamCourierConfig) {
        self.networkConfig = networkConfig
        self.performQueue = performOnQueue
        self.courierConfig = courierConfig
    }

    func initiateConnection(connectionStatusListener: ConnectionStatus?, keepTrying: Bool = false) {
        performQueue.async {
            self.courierClient?.connect(source: "clickstream")
            self.courierClient?.connectionStatePublisher.sink { state in
                switch state {
                case .connected:
                    connectionStatusListener?(.success(.connected))
                case .connecting:
                    connectionStatusListener?(.success(.connecting))
                case .disconnected:
                    connectionStatusListener?(.failure(.failed))
                }
            }.store(in: &self.courierCancellables)
        }
    }

    func write<T>(_ data: Data, completion: @escaping (Result<T, ConnectableError>) -> Void) where T : SwiftProtobuf.Message {
        performQueue.async {
            do {
                try self.courierClient?.publishMessage(data, topic: self.currentTopic, qos: .one)

                self.courierClient?.messagePublisher(topic: self.currentTopic).sink { (data: Data) in
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
        performQueue.async {
            self.unsubscribeTopics()
            self.courierClient?.destroy()
            self.courierClient?.disconnect()
        }
    }

    func flushConnectable() {
        performQueue.async {
            self.unsubscribeTopics()
            self.courierClient?.destroy()
        }
    }
}


extension CourierNetworkService {

    /// Configure upon user has authenticated
    /// - Parameter userCredentials: user's credentials
    func configureCourierClient(with userCredentials: ClickstreamCourierUserCredentials) async {
        let messageAdapters: [MessageAdapter] = courierConfig.messageAdapters.compactMap({
            CourierMessageAdapterType.mapped(from: $0)
        })
        
        let authService = CourierAuthenticationProvider(config: courierConfig,
                                                        userCredentials: userCredentials,
                                                        applicationState: UIApplication.State.active,
                                                        networkTypeProvider: .wifi)
        
        let mqttConfig = MQTTClientConfig(topics: topics,
                                          authService: authService,
                                          messageAdapters: messageAdapters,
                                          isMessagePersistenceEnabled: courierConfig.isMessagePersistenceEnabled,
                                          autoReconnectInterval: UInt16(courierConfig.autoReconnectInterval),
                                          maxAutoReconnectInterval: UInt16(courierConfig.maxAutoReconnectInterval),
                                          enableAuthenticationTimeout: courierConfig.enableAuthenticationTimeout,
                                          authenticationTimeoutInterval: courierConfig.authenticationTimeoutInterval,
                                          connectTimeoutPolicy: courierConfig.connectTimeoutPolicy,
                                          idleActivityTimeoutPolicy: courierConfig.iddleActivityPolicy,
                                          messagePersistenceTTLSeconds: courierConfig.messagePersistenceTTLSeconds,
                                          messageCleanupInterval: courierConfig.messageCleanupInterval,
                                          shouldInitializeCoreDataPersistenceContext: courierConfig.shouldInitializeCoreDataPersistenceContext)
        
        courierClient = CourierClientFactory().makeMQTTClient(config: mqttConfig)
    }

    /// Establish connection on upon initial Courier's client setup
    func establishConnection() async {
        var retryCounter = courierConfig.maxAutoReconnectInterval

        initiateConnection(connectionStatusListener: { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let state):
                switch state {
                case .connected:
                    self.subscribeTopics()
                    self.observedMessagePublisher()
                case .disconnected:
                    retryCounter -= 1
                case .connecting, .cancelled:
                    return
                }
            case .failure:
                retryCounter -= 1
            }
        }, keepTrying: retryCounter > 1)
    }

    private func observedMessagePublisher() {
        messagePublisher = self.courierClient?.messagePublisher()
        messagePublisher?.sink { message in
            // Process the message
        }.store(in: &courierCancellables)
    }

    private func subscribeTopics() {
        performQueue.async {
            self.topics.forEach {
                self.courierClient?.subscribe(($0.key, $0.value))
            }
        }
    }

    private func unsubscribeTopics() {
        performQueue.async {
            let topics = Array(self.topics.keys)
            self.courierClient?.unsubscribe(topics)
        }
    }
}
