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

public typealias CourierConnectOptionsObserver = (_ connectOptions: ConnectOptions) -> Void

protocol CourierHandler: CourierConnectable { }

final class DefaultCourierHandler: CourierHandler {

    private var courierClient: CourierClient?
    private var config: ClickstreamCourierClientConfig
    private var userCredentials: ClickstreamClientIdentifiers
    private var cancellables: Set<CourierCore.AnyCancellable> = []
    private var connectOptionsObserver: CourierConnectOptionsObserver?
    private lazy var authServiceProvider: IConnectionServiceProvider = {
        CourierAuthenticationProvider(config: config,
                                      userCredentials: userCredentials,
                                      networkTypeProvider: Reachability.getNetworkType())
    }()
    
    var isConnected: Atomic<Bool> {
        .init(courierClient?.connectionState == .connected)
    }

    init(config: ClickstreamCourierClientConfig,
         userCredentials: ClickstreamClientIdentifiers,
         connectOptionsObserver: CourierConnectOptionsObserver?) {

        self.config = config
        self.userCredentials = userCredentials
        self.connectOptionsObserver = connectOptionsObserver
    }
    
    func publishMessage(_ eventRequest: CourierEventRequest, topic: String) async throws {
        guard let data = eventRequest.data else {
            throw CourierError.encodingError
        }
        try courierClient?.publishMessage(data, topic: topic, qos: .oneWithoutPersistenceAndRetry)
    }
    
    func destroyAndDisconnect() {
        courierClient?.destroy()
    }

    func setup(request: URLRequest, connectionCallback: ConnectionStatus?, eventHandler: ICourierEventHandler) async {
        courierClient = await getCourierClient()
        courierClient?.addEventHandler(eventHandler)

        await connect(connectionCallback: connectionCallback)
    }
}

extension DefaultCourierHandler {

    private func getCourierClient() async -> CourierClient {
        let connectPolicy = ConnectTimeoutPolicy(isEnabled: config.courierConnectTimeoutPolicyEnabled,
                                                 timerInterval: TimeInterval(config.courierConnectTimeoutPolicyIntervalMillis),
                                                 timeout: TimeInterval(config.courierInactivityPolicyTimeoutMillis))

        let idleActivityPolicy = IdleActivityTimeoutPolicy.init(isEnabled: config.courierInactivityPolicyEnabled,
                                                                timerInterval: TimeInterval(config.courierInactivityPolicyIntervalMillis),
                                                                inactivityTimeout: TimeInterval(config.courierInactivityPolicyTimeoutMillis),
                                                                readTimeout: TimeInterval(config.courierInactivityPolicyReadTimeoutMillis))

        let mqttConfig = MQTTClientConfig(authService: authServiceProvider,
                                          messageAdapters: config.courierMessageAdapter,
                                          isMessagePersistenceEnabled: config.courierMessagePersistenceEnabled,
                                          autoReconnectInterval: UInt16(config.courierAutoReconnectIntervalSecs),
                                          maxAutoReconnectInterval: UInt16(config.courierAutoReconnectMaxIntervalSecs),
                                          enableAuthenticationTimeout: config.courierAuthTimeoutEnabled,
                                          authenticationTimeoutInterval: TimeInterval(config.courierAuthTimeoutIntervalSecs),
                                          connectTimeoutPolicy: connectPolicy,
                                          idleActivityTimeoutPolicy: idleActivityPolicy,
                                          messagePersistenceTTLSeconds: TimeInterval(config.courierMessagePersistenceTTLSecs),
                                          messageCleanupInterval: TimeInterval(config.courierMessageCleanupInterval),
                                          shouldInitializeCoreDataPersistenceContext: config.courierInitCoreDataPersistenceContextEnabled)

        return CourierClientFactory().makeMQTTClient(config: mqttConfig)
    }

    private func connect(connectionCallback: ConnectionStatus?) async {
        courierClient?.connect(source: "clickstream")
        courierClient?.connectionStatePublisher.sink { [weak self] state in
            switch state {
            case .connected:
                if let connectOptions = self?.authServiceProvider.existingConnectOptions {
                    self?.connectOptionsObserver?(connectOptions)
                }
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
