//
//  CourierHandler.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 22/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import Combine
import CourierCore
import CourierMQTT
import Reachability

protocol CourierHandler: CourierConnectable { }

final class DefaultCourierHandler: CourierHandler {

    private var courierClient: CourierClient?
    private var courierConfig: ClickstreamCourierConfig
    private var userCredentials: ClickstreamClientIdentifiers
    private var cancellables: Set<CourierCore.AnyCancellable> = []
    private var topics: [String: QoS]?

    private lazy var authServiceProvider: IConnectionServiceProvider = {
        CourierAuthenticationProvider(config: courierConfig,
                                      userCredentials: userCredentials,
                                      networkTypeProvider: Reachability.getNetworkType())
    }()

    var isConnected: Atomic<Bool> {
        .init(courierClient?.connectionState == .connected)
    }

    init(config: ClickstreamCourierConfig, userCredentials: ClickstreamClientIdentifiers) {
        self.courierConfig = config
        self.userCredentials = userCredentials
    }

    func publishMessage(_ data: Data) throws {
        // Commented-out for debugging prupose
//        guard let eventRequest = try? Odpf_Raccoon_EventRequest(serializedBytes: data) else {
//            return
//        }
//        
//        let events = eventRequest.events.compactMap {
//            try? Odpf_Raccoon_Event(serializedBytes: $0.eventBytes)
//        }

        try courierClient?.publishMessage(data, topic: "", qos: .one)
    }
    
    func disconnect() {
        unsubscribeTopics()
        courierClient?.destroy()
        courierClient?.disconnect()
    }

    func setup(request: URLRequest,
               keepTrying: Bool,
               connectionCallback: ConnectionStatus?) async {

        courierClient = await getCourierClient()

        await connect(connectionCallback: connectionCallback)
        
        subscribeTopics()
    }
}

extension DefaultCourierHandler {

    private func getCourierClient() async -> CourierClient {
        let topics = courierConfig.topics.compactMapValues { QoS(value: $0) }

        let mqttConfig = MQTTClientConfig(topics: topics,
                                          authService: authServiceProvider,
                                          messageAdapters: courierConfig.messageAdapters,
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

        return CourierClientFactory().makeMQTTClient(config: mqttConfig)
    }

    private func connect(connectionCallback: ConnectionStatus?) async {
        courierClient?.connect(source: "clickstream")
        courierClient?.connectionStatePublisher.sink { state in
            switch state {
            case .connected:
                connectionCallback?(.success(.connected))
            case .connecting:
                connectionCallback?(.success(.connecting))
            case .disconnected:
                connectionCallback?(.failure(.failed))
            }
        }.store(in: &cancellables)
    }

    private func subscribeTopics() {
        guard let topics, !topics.isEmpty else { return }

        topics.forEach {
            courierClient?.subscribe(($0.key, $0.value))
        }
    }

    private func unsubscribeTopics() {
        guard let topics, !topics.isEmpty else { return }

        let keys = Array(topics.keys)
        courierClient?.unsubscribe(keys)
    }
}
