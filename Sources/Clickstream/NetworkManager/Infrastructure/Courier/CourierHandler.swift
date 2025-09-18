//
//  CourierHandler.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 16/09/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import Reachability
import CourierCore
import CourierMQTT

protocol CourierHandler: Connectable { }

final class DefaultCourierHandler: CourierHandler {
    
    typealias TopicQoS = (topic: String, qos: QoS)
    
    /// Used as a websocket callback queue.
    private let performQueue: SerialQueue
    
    /// States whether the socket request is open.
    private var isConnectionRequestOpen: Bool = false
    
    /// Refers to the `URLRequest` for setting up a socket connection
    private var request: URLRequest?
    
    /// Callback for the socket status
    private var connectionCallback: ConnectionStatus?
    
    /// Holds the number of retries made for negotiating a connection.
    private static var retries = 0
    
    /// CourierClient instance
    private var courierClient: CourierClient?

    /// CourierClient instance
    private var courierSubscribtions: [TopicQoS] {
        [(topic: "", qos: .one), (topic: "", qos: .one)]
    }

    /// CourierClient's cancellable store
    private var courierCancellables: Set<AnyCancellable> = []

    /// Callback for a socket `write` action
    private var writeCallback: ((Result<Data?, ConnectableError>) -> Void)?
    
    /// Tracking time taken by the socket to establish a connection
    #if TRACKER_ENABLED
    private var courierConnectionTimeTrace: Trace = Trace(name: TrackerConstant.Traces.ClickstreamSocketConnectionTime.rawValue)
    #endif
    
    /// Provides the socket state
    var isConnected: Atomic<Bool> = Atomic(false)
    
    /// Records the time stamp for the last connection request made
    private var lastConnectRequestTimestamp: Date?

    /// Custom Socket Handler initialiser
    /// - Parameter performOnQueue: Queue on which a socket performs actions
    init(performOnQueue: SerialQueue) {
        self.performQueue = performOnQueue
        DefaultCourierHandler.retries = 0
    }
    
    /// Attempt at making a connection
    /// - Parameters:
    ///   - request: URLRequest for setting up socket connection
    ///   - keepTrying: Suggests if the connection attempts should tried multiple times
    ///   - connectionCallback: Connection callback closure provides with the state of the socket as `ConnectionStatus`
    func setup(request: URLRequest,
               keepTrying: Bool,
               connectionCallback: ConnectionStatus?) {
        
        guard self.isConnectionRequestOpen == false || !request.isEqual(to: self.request) else { return }
        self.isConnected.mutate { isConnected in
            isConnected = false
        }
        self.connectionCallback = connectionCallback
        self.request = request
        
        self.courierClient = CourierClientFactory().makeMQTTClient(config:
            MQTTClientConfig(
                topics: [:],
                authService: CourierConnectionServiceProvider(clientId: "user_id", extraIdProvider: ""),
                messageAdapters: [JSONMessageAdapter()],
                isMessagePersistenceEnabled: false,
                autoReconnectInterval: 5,
                maxAutoReconnectInterval: 10,
                enableAuthenticationTimeout: false,
                authenticationTimeoutInterval: 30,
                connectTimeoutPolicy: ConnectTimeoutPolicy(),
                idleActivityTimeoutPolicy: IdleActivityTimeoutPolicy(),
                messagePersistenceTTLSeconds: 0,
                messageCleanupInterval: 10,
                shouldInitializeCoreDataPersistenceContext: true
            )
        )

        // Add courier connection & event listeners
        addCourierConnectionListener()
        addCourierEventsListener()
        
        // Negotiate connection
        if keepTrying {
            negotiateConnection(initiate: true,
                                maxInterval: Clickstream.configurations.maxConnectionRetryInterval,
                                maxRetries: Clickstream.configurations.maxConnectionRetries)
        } else {
            negotiateConnection(initiate: true)
        }
    }

    /// Negotiates a connection, by calling the
    /// - Parameters:
    ///   - initiate: A control flag to control whether the negotiation should de initiated or not.
    ///   - maxInterval: A given max interval for the retries.
    ///   - maxRetries: A given number of max retry attempts
    private func negotiateConnection(initiate: Bool,
                                     maxInterval: TimeInterval = 0.0,
                                     maxRetries: Int = 0) {
        
        if isConnected.value || DefaultCourierHandler.retries > maxRetries {
            // Exit Condition.
            // Reset to zero for further negotiation calls.
            DefaultCourierHandler.retries = 0
            return
        } else if initiate || DefaultCourierHandler.retries > 0 {
            if !isConnectionRequestOpen ||
                Date().timeIntervalSince(lastConnectRequestTimestamp ?? Date()) > self.request?.timeoutInterval ?? 60 {
                Clickstream.connectionState = .connecting
                print("socket-connecting")
                isConnectionRequestOpen = true
                connectionCallback?(.success(.connecting))
                #if TRACKER_ENABLED
                courierConnectionTimeTrace.attributes = [Constants.Strings.networkType: Reachability.getNetworkType().trackingId]
                courierConnectionTimeTrace.start()
                #endif
                
                courierClient?.connect()
                lastConnectRequestTimestamp = Date() // recording time
            }
        }
        if DefaultCourierHandler.retries < maxRetries {
            performQueue.asyncAfter(deadline: .now() +
                                    min(pow(Constants.Defaults.coefficientOfConnectionRetries*connectionRetryCoefficient,
                                            Double(DefaultCourierHandler.retries)), maxInterval)) {
                [weak self] in guard let checkedSelf = self else { return }
                checkedSelf.negotiateConnection(initiate: false,
                                                maxInterval: maxInterval,
                                                maxRetries: maxRetries)
            }
            DefaultCourierHandler.retries += 1
        }
    }
    
    deinit {
        #if TRACKER_ENABLED
        courierConnectionTimeTrace.attributes = [Constants.Strings.networkType: Reachability.getNetworkType().trackingId,
                                                Constants.Strings.status: Constants.Strings.failure]
        courierConnectionTimeTrace.stop()
        #endif
    }
}

extension DefaultCourierHandler {
    
    /// Writing data on the socket connection.
    /// - Parameters:
    ///   - data: data to be returned
    ///   - completion: completion callback
    func write(_ data: Data, completion: @escaping ((Result<Data?, ConnectableError>) -> Void)) {
        courierClient?.messagePublisher()
            .sink { _ in
                self.writeCallback = completion
            }.store(in: &courierCancellables)
    }
    
    /// Call this to disconnect from the socket.
    func disconnect() {
        courierClient?.disconnect()
        Clickstream.connectionState = .closed
        reset()
    }
    
    /// Resets the state variables and socket event listeners.
    private func reset() {
        courierClient?.destroy()
        removeCourierEventsListener()

        isConnectionRequestOpen = false
        self.isConnected.mutate { isConnected in
            isConnected = false
        }
    }
}

extension DefaultCourierHandler {

    private func addCourierConnectionListener() {
        courierClient?.connectionStatePublisher
            .sink { connectionState in
                if connectionState == .connected {
                    
                }
            }
            .store(in: &courierCancellables)
    }

    private func addCourierEventsListener() {
        courierSubscribtions.forEach {
            courierClient?.subscribe(($0.topic, $0.qos))
        }
    }
    
    private func removeCourierEventsListener() {
        courierSubscribtions.forEach {
            courierClient?.unsubscribe($0.topic)
        }
    }
    
    /// Retries socket connection when `.cancelled` state of the socket is received.
    private func retryConnection() {
        isConnectionRequestOpen = false
        isConnected.mutate { isConnected in
            isConnected = false
        }
    }
}

extension CourierHandler {
    var connectionRetryCoefficient: TimeInterval {
        get {
            let networkType = Reachability.getNetworkType()
            switch networkType {
            case .wifi:
                return 1
            case .wwan4g, .wwan5g:
                return 1.3
            case .wwan3g:
                return 1.6
            case .wwan2g:
                return 2.2
            default:
                return 1
            }
        }
    }
}

extension DefaultCourierHandler {
#if TRACKER_ENABLED
    func trackHealthEvent(eventName: HealthEvents,
                          error: Error? = nil,
                          code: UInt16? = nil,
                          timeToConnection: String? = nil) {
        
        guard Tracker.debugMode else { return }
        
    }
#endif
}
