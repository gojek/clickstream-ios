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

    /// Serialises access to `courierClient` and `isClientTornDown`.
    ///
    /// `destroyAndDisconnect()` tears the Courier client down while `publishMessage(_:topic:)`
    /// may be running on the retry mechanism's own queue. `CourierClient.destroy()` nils the
    /// underlying MQTT session and kicks off a Core Data wipe on Courier's internal queue, so
    /// publishing into a torn-down client is a use-after-free — it crashed in `objc_retain`
    /// while reading the session, and in `objc_msgSend` inside `-[MQTTSession nextMsgId]`.
    ///
    /// Courier tracks its own `isDestroyed` flag but does not expose it on the `CourierClient`
    /// protocol, so the teardown state has to be latched here.
    private let clientAccessQueue = DispatchQueue(label: Constants.CourierQueueIdentifiers.courierClientAccess.rawValue,
                                                  attributes: .concurrent)

    private var courierClient: CourierClient?
    private var isClientTornDown = false
    private var config: ClickstreamCourierClientConfig
    private var userCredentials: ClickstreamClientIdentifiers
    private var cancellables: Set<CourierCore.AnyCancellable> = []
    private var pubSubAnalytics: ICourierEventHandler?

    /// Kill switch for the teardown guard. Captured with `config` at init, never re-read
    /// per call: a value that flipped mid-flight would leave one thread guarding and another
    /// not, which is still a use-after-free while reporting as enabled.
    private let isTeardownGuardEnabled: Bool

    /// The live client, or `nil` once it has been torn down. Guarded path only — with the
    /// kill switch off every call site reads `courierClient` directly, as it did before
    /// the fix.
    private var activeClient: CourierClient? {
        clientAccessQueue.sync { isClientTornDown ? nil : courierClient }
    }

    var isConnected: Atomic<Bool> {
        guard isTeardownGuardEnabled else {
            return .init(courierClient?.connectionState == .connected)
        }
        return .init(activeClient?.connectionState == .connected)
    }

    init(config: ClickstreamCourierClientConfig,
         userCredentials: ClickstreamClientIdentifiers,
         pubSubAnalytics: ICourierEventHandler?) {

        self.config = config
        self.userCredentials = userCredentials
        self.pubSubAnalytics = pubSubAnalytics
        self.isTeardownGuardEnabled = config.fixPublishAfterDestroyCrash
    }
    
    func publishMessage(_ eventRequest: CourierEventRequest, topic: String) throws {
        guard let data = eventRequest.data else {
            throw CourierError.encodingError
        }
        let resolvedQoS: QoS
        if let qosValue = eventRequest.qos, let classificationQoS = QoS(value: qosValue) {
            resolvedQoS = classificationQoS
        } else {
            resolvedQoS = QoS(rawValue: config.courierQoSType) ?? .oneWithoutPersistenceAndRetry
        }
        guard isTeardownGuardEnabled else {
            try courierClient?.publishMessage(data, topic: topic, qos: resolvedQoS)
            return
        }

        // Snapshot the client reference and the teardown latch in one atomic step, so the
        // client cannot be destroyed between the check and the call.
        let snapshot: (client: CourierClient?, isTornDown: Bool) = clientAccessQueue.sync {
            (courierClient, isClientTornDown)
        }

        // Publishing into a destroyed client is a use-after-free. Throwing leaves the event
        // in the retry cache (it is added before this call), so nothing is lost.
        guard !snapshot.isTornDown else {
            throw CourierError.sessionNotExist
        }

        // A nil client that was never set up stays a no-op, as before.
        try snapshot.client?.publishMessage(data, topic: topic, qos: resolvedQoS)
    }
    
    func destroyAndDisconnect() {
        guard isTeardownGuardEnabled else {
            courierClient?.destroy()
            return
        }

        // Latch first so any concurrent publish bails out, then destroy outside the
        // barrier: `destroy()` runs disconnect handlers synchronously, which can re-enter
        // this type (for example via `isConnected`) and would deadlock on the barrier.
        let client: CourierClient? = clientAccessQueue.sync(flags: .barrier) {
            guard !isClientTornDown else { return nil }
            isClientTornDown = true
            let client = courierClient
            courierClient = nil
            return client
        }
        client?.destroy()
    }

    func setup(authProvider: IConnectionServiceProvider,
               connectionCallback: ConnectionStatus?,
               eventHandler: ICourierEventHandler) {

        guard isTeardownGuardEnabled else {
            courierClient?.destroy()
            cancellables.removeAll()

            courierClient = getCourierClient(authServiceProvider: authProvider)
            courierClient?.addEventHandler(eventHandler)

            if let pubSubAnalytics {
                courierClient?.addEventHandler(pubSubAnalytics)
            }

            connect(connectionCallback: connectionCallback)
            return
        }

        destroyAndDisconnect()
        cancellables.removeAll()

        let client = getCourierClient(authServiceProvider: authProvider)
        client.addEventHandler(eventHandler)

        if let pubSubAnalytics {
            client.addEventHandler(pubSubAnalytics)
        }

        // Publish the new client and re-arm the latch only once it is fully configured.
        clientAccessQueue.sync(flags: .barrier) {
            courierClient = client
            isClientTornDown = false
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
                                          isMessageInMemoryPersistenceEnabled: config.courierMessagePersistenceInMemoryEnabled,
                                          autoReconnectInterval: UInt16(config.courierAutoReconnectIntervalSecs),
                                          maxAutoReconnectInterval: UInt16(config.courierAutoReconnectMaxIntervalSecs),
                                          enableAuthenticationTimeout: config.courierAuthTimeoutEnabled,
                                          authenticationTimeoutInterval: TimeInterval(config.courierAuthTimeoutIntervalSecs),
                                          connectTimeoutPolicy: connectPolicy,
                                          idleActivityTimeoutPolicy: idleActivityPolicy,
                                          messagePersistenceTTLSeconds: TimeInterval(config.courierMessagePersistenceTTLSecs),
                                          messageCleanupInterval: TimeInterval(config.courierMessageCleanupInterval),
                                          shouldInitializeCoreDataPersistenceContext: config.courierInitCoreDataPersistenceContextEnabled,
                                          fixCxxDestructCrash: config.fixCxxDestructCrash,
                                          useSafeDeleteForNonSQLiteStore: config.useSafeDeleteForNonSQLiteStore,
                                          serializeSessionAccess: config.serializeSessionAccess)

        return CourierClientFactory().makeMQTTClient(config: mqttConfig)
    }

    private func connect(connectionCallback: ConnectionStatus?) {
        guard isTeardownGuardEnabled else {
            courierClient?.connect(source: "clickstream")
            courierClient?.connectionStatePublisher.sink { state in
                Self.notify(state: state, to: connectionCallback)
            }.store(in: &cancellables)
            return
        }

        guard let client = activeClient else { return }
        client.connect(source: "clickstream")
        client.connectionStatePublisher.sink { state in
            Self.notify(state: state, to: connectionCallback)
        }.store(in: &cancellables)
    }

    private static func notify(state: ConnectionState, to connectionCallback: ConnectionStatus?) {
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
    }
}
