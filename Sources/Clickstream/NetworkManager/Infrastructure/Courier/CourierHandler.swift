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
    private var config: ClickstreamCourierClientConfig
    private var userCredentials: ClickstreamClientIdentifiers
    private var cancellables: Set<CourierCore.AnyCancellable> = []
    private var pubSubAnalytics: ICourierEventHandler?

    var isConnected: Atomic<Bool> {
        .init(courierClient?.connectionState == .connected)
    }

    init(config: ClickstreamCourierClientConfig,
         userCredentials: ClickstreamClientIdentifiers,
         pubSubAnalytics: ICourierEventHandler?) {

        self.config = config
        self.userCredentials = userCredentials
        self.pubSubAnalytics = pubSubAnalytics
    }
    
    func publishMessage(_ eventRequest: CourierEventRequest, topic: String) throws {
        guard let data = eventRequest.data else {
            throw CourierError.encodingError
        }
        let qos: QoS = .init(rawValue: config.courierQoSType) ?? .oneWithoutPersistenceAndRetry
        try courierClient?.publishMessage(data, topic: topic, qos: qos)
    }
    
    func destroyAndDisconnect() {
        courierClient?.destroy()
    }

    func setup(authProvider: IConnectionServiceProvider,
               connectionCallback: ConnectionStatus?,
               eventHandler: ICourierEventHandler) {

        courierClient = getCourierClient(authServiceProvider: authProvider)
        courierClient?.addEventHandler(eventHandler)

        if let pubSubAnalytics {
            courierClient?.addEventHandler(pubSubAnalytics)
        }

        connect(connectionCallback: connectionCallback)
    }
}

extension DefaultCourierHandler {

    private func getCourierClient(authServiceProvider: IConnectionServiceProvider) -> CourierClient {
        let connectPolicy = ConnectTimeoutPolicy(isEnabled: config.courierConnectPolicy.isEnabled,
                                                 timerInterval: TimeInterval(config.courierConnectPolicy.intervalSecs),
                                                 timeout: TimeInterval(config.courierConnectPolicy.timeoutSecs))

        let idleActivityPolicy = IdleActivityTimeoutPolicy.init(isEnabled: config.courierInactivityPolicy.isEnabled,
                                                                timerInterval: TimeInterval(config.courierInactivityPolicy.intervalSecs),
                                                                inactivityTimeout: TimeInterval(config.courierInactivityPolicy.timeoutSecs),
                                                                readTimeout: TimeInterval(config.courierInactivityPolicy.readTimeoutSecs))

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

    private func connect(connectionCallback: ConnectionStatus?) {
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
