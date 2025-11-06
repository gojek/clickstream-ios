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

    private var racoonURLRequest: URLRequest?
    private var pollingService: PollingFallbackServiceInterface?
    private var pollingResult: Result<Odpf_Raccoon_EventResponse, Error>?

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
    
    func publishMessage(_ eventRequest: EventRequest, topic: String) async throws {
        guard let data = eventRequest.data else {
            throw ConnectableError.failed
        }
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
        racoonURLRequest = request

        if let eventHandler {
            courierClient?.addEventHandler(eventHandler)
        }

        await setupPollingFallbackService()
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

extension DefaultCourierHandler: PollingMessageListener, PollingEventHandler {

    private func setupPollingFallbackService() async {
        if let networkClient = try? createNetworkClient() {
            let policies = createFallbackPolicies(delay: 0, maxRetryCout: 0)
            let config = CourierFallbackPollingConfig(pollingInterval: 0)

            pollingService = createFallbackPollingService(networkClient: networkClient,
                                                          policies: policies,
                                                          config: config)
            pollingService?.start()
        }
    }

    private func createFallbackPollingService(
        networkClient: CourierNetworkClient<Odpf_Raccoon_EventResponse, Message>,
        policies: [FallbackPolicy],
        config: CourierFallbackPollingConfig) -> PollingFallbackServiceInterface {

        CourierFallbackPolling(
            networkClient: networkClient,
            messageListener: self,
            policies: policies,
            eventHandler: self,
            config: config
        )
    }

    private func createFallbackPolicies(delay: TimeInterval, maxRetryCout: Int) -> [FallbackPolicy] {
        let publishPolicy = PublishFallbackPolicy(delay: delay)
        return [publishPolicy]
    }
    
    private func createNetworkClient() throws -> CourierNetworkClient<Odpf_Raccoon_EventResponse, Message> {
        guard let courierClient else {
            throw NSError(domain: "com.clickstream.courier.fallback", code: 01)
        }

        let messagePublisher: CourierCore.AnyPublisher<Message, Never> = courierClient.messagePublisher()

        let client = try CourierNetworkClient<Odpf_Raccoon_EventResponse, Message>(
            httpResultHandler: { [weak self] handler in
                guard let self, let result = pollingResult else { return }
                handler(result)
            },
            courierMessagePublisher: messagePublisher,
            courierMessageMapper: nil
        )
        
        return client
    }

    private func executeRequest(with request: URLRequest, result: (@escaping (Result<T, Error>) -> Void)) {
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error {
                result(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                let statusCode: Int = (response as? HTTPURLResponse)?.statusCode ?? -1
                result(.failure(ConnectableError.networkError(NSError(domain: "HTTP Status Code: \(statusCode)", code: 3))))
                return
            }

            guard let data, let eventResponse = try? Odpf_Raccoon_EventResponse(jsonUTF8Data: data) else {
                result(.failure(NSError(domain: "Decoding Error", code: 3)))
                return
            }
            
            result(.success(eventResponse))
        }
    }

    // MARK: - MessageListener
    func onMessageReceived(_ message: Odpf_Raccoon_EventResponse, source: PollingMessageSource) {
        return
    }

    // MARK: - PollingEventHandler
    func onEvent(_ event: PollingEvent) {
        if let pollingTriggered = event as? PollingTriggeredEvent {
            let type = pollingTriggered.type
            let source = pollingTriggered.source

            switch type {
            case .enabled:
                return
            case .disabled:
                return
            }
        }
    }
}
