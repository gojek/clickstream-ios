//
//  CourierFallbackPollingService.swift
//  CourierFallbackPollingService
//
//  Created by Alfian Losari on 03/02/23.
//

import CourierCore
import CourierMQTT
import Foundation
import MQTTClientGJ

final class CourierFallbackPolling<N: NetworkClient, M: PollingMessageListener>: PollingFallbackServiceInterface
    where N.T == M.T {

    private let networkClient: N
    private let messageListener: M
    private let policies: [FallbackPolicy]
    private let config: FallbackToPollingConfig

    internal var operationQueue: OperationQueue
    private let messageQueue: DispatchQueue

    weak var eventHandler: PollingEventHandler?

    let currentMessageSubject = CurrentValueSubject<(value: M.T, source: PollingMessageSource)?, Never>(nil)
    private var cancellable: AnyCancellable?

    @CourierAtomic<GCDTimer?>(nil)
    private var pollingTimer

    @CourierAtomic<Bool>(false)
    private var _isStarted
    var isStarted: Bool {
        _isStarted
    }

    init(
        networkClient: N,
        messageListener: M,
        policies: [FallbackPolicy],
        eventHandler: PollingEventHandler,
        config: FallbackToPollingConfig,
    ) {
        self.networkClient = networkClient
        self.messageListener = messageListener
        self.policies = policies
        self.eventHandler = eventHandler
        self.config = config
        
        let messageQueue = DispatchQueue(label: "com.clickstream.courier.fallbackpolling", qos: .userInitiated)
        self.messageQueue = messageQueue

        let queue = OperationQueue()
        queue.underlyingQueue = messageQueue
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        self.operationQueue = queue
    }

    func start() {
        guard !isStarted else { return }
        _isStarted = true

        cancelSubscription()
        self.cancellable = currentMessageSubject.sink { [weak self] value in
            guard let messageListener = self?.messageListener, let value = value else { return }
            messageListener.onMessageReceived(value.value, source: value.source)
        }

        policies.forEach { $0.start(service: self) }
        
        listenFromCourier()
    }

    func stop() {
        _isStarted = false
        
        cancelSubscription()
        currentMessageSubject.send(nil)
        
        networkClient.cancelPendingHTTPRequest()
        networkClient.cancelCourierListener()
        policies.forEach { $0.stop() }

        stopPolling()
    }

    func listenFromCourier() {
        networkClient.listenFromCourier { [weak self] in
            self?.handleMessageResult($0, source: .courier)
        }
    }

    func fetchFromHTTP() {
        networkClient.fetchFromHTTP { [weak self] in
            self?.handleMessageResult($0, source: .http)
        }
    }

    func handleMessageResult(_ result: Result<N.T, Error>, source: PollingMessageSource) {
        guard self.isStarted else { return }
        switch result {
        case .success(let value):
            self.messageQueue.async { [weak self] in
                self?.currentMessageSubject.send((value, source))
            }
            self.eventHandler?.onEvent(PollingMessageReceivedEvent(source: source))
        case .failure(let error):
            self.eventHandler?.onEvent(PollingMessageReceiveFailureEvent(source: source,
                                                                         error: error.localizedDescription))
        }
    }

    func cancelSubscription() {
        cancellable?.cancel()
        cancellable = nil
    }

    deinit {
        stopPolling()
        networkClient.cancelCourierListener()
        cancelSubscription()
    }
}

extension CourierFallbackPolling: PollingService {

    func enablePolling(source: String) {
        guard pollingTimer == nil else { return }
        self.pollingTimer = GCDTimer.scheduledTimer(withTimeInterval: self.config.pollingInterval, repeats: true, queue: messageQueue) { [weak self] in
            self?.fetchFromHTTP()
        }
        self.fetchFromHTTP()
        eventHandler?.onEvent(PollingTriggeredEvent(source: source, type: .enabled))
    }

    func disablePolling(source: String) {
        guard pollingTimer != nil else { return }
        stopPolling()
        eventHandler?.onEvent(PollingTriggeredEvent(source: source, type: .disabled))
    }

    func stopPolling() {
        networkClient.cancelPendingHTTPRequest()
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}
