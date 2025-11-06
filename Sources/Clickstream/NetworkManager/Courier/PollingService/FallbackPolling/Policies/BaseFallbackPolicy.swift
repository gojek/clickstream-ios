//
//  BaseFallbackPolicy.swift
//  CourierFallbackPollingService
//
//  Created by Alfian Losari on 08/02/23.
//

import CourierCore
import Foundation

open class BaseFallbackPolicy: FallbackPolicy, ICourierEventHandler {

    let delay: TimeInterval
    weak var pollingService: PollingService?
    var currentOperation: AsyncOperation?

    var startCallback: (() -> Void)?

    var source: String {
        NSStringFromClass(Self.self)
    }

    var operationQueue: OperationQueue? { pollingService?.operationQueue }
    var dispatchQueue: DispatchQueue {
        pollingService?.operationQueue.underlyingQueue ?? .main
    }

    init(delay: TimeInterval, startCallback: (() -> Void)? = nil) {
        self.delay = delay
        self.startCallback = startCallback
    }

    func start(service: PollingService) {
        dispatchQueue.async { [weak self] in
            self?.cancel()
            self?.pollingService = service
            self?.startCallback?()
        }
    }

    func stop() {
        dispatchQueue.async { [weak self] in
            self?.pollingService = nil
            self?.cancel()
        }
    }

    func schedule() {
        dispatchQueue.async { [weak self] in
            guard let self = self,
                  self.pollingService != nil,
                  self.currentOperation == nil,
                  self.operationQueue != nil
            else {
                return
            }

            let operation = AsyncOperation(
                delay: self.delay,
                delayCallback: { [weak self] in
                    guard let self else { return }
                    self.handleSchedule()
                }, dispatchQueue: self.dispatchQueue
            )

            self.currentOperation = operation
            operationQueue?.addOperation(operation)
        }
    }

    func handleSchedule() {
        guard let pollingService = self.pollingService else { return }
        pollingService.enablePolling(source: source)
        self.currentOperation = nil
    }

    public func cancel() {
        self.cancelOperation()
        self.pollingService?.disablePolling(source: source)
    }

    func cancelOperation() {
        self.currentOperation?.cancel()
        self.currentOperation = nil
    }

    open func onEvent(_ event: CourierEvent) {
        fatalError("Please override and implement in your subclass")
    }

    deinit {
        self.pollingService = nil
        self.currentOperation?.cancel()
        self.currentOperation = nil
    }
}
