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
    private var topic: String?

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

    func publishMessage(_ data: Data, topic: String) async throws {
        try courierClient?.publishMessage(data, topic: topic, qos: .oneWithoutPersistenceAndRetry)
    }
    
    func disconnect() {
        courierClient?.destroy()
        courierClient?.disconnect()
    }

    func setup(request: URLRequest,
               keepTrying: Bool,
               connectionCallback: ConnectionStatus?,
               eventHandler: ICourierEventHandler? = nil) async {

        courierClient = await getCourierClient()

        if let eventHandler {
            courierClient?.addEventHandler(eventHandler)
        }

        await connect(connectionCallback: connectionCallback)
    }
}

extension DefaultCourierHandler {

    private func getCourierClient() async -> CourierClient {
        let mqttConfig = MQTTClientConfig(authService: authServiceProvider,
                                          messageAdapters: courierConfig.messageAdapters,
                                          isMessagePersistenceEnabled: courierConfig.isMessagePersistenceEnabled,
                                          autoReconnectInterval: UInt16(courierConfig.connectConfig.autoReconnectInterval),
                                          maxAutoReconnectInterval: UInt16(courierConfig.connectConfig.maxAutoReconnectInterval),
                                          enableAuthenticationTimeout: courierConfig.connectConfig.enableAuthenticationTimeout,
                                          authenticationTimeoutInterval: courierConfig.connectConfig.authenticationTimeoutInterval,
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
            @unknown default:
                return
            }
        }.store(in: &cancellables)
    }
}
