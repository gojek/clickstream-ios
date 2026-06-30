//
//  CourierClassificationScheduler.swift
//  Clickstream
//
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

/// A per-classification scheduler that owns its storage, ticker, batching, and QoS.
///
/// Mirrors the Android `CourierEventScheduler`. Each instance handles exactly one
/// classification, identified by `classificationId`.
protocol CourierEventScheduling: AnyObject {

    /// The classification this scheduler serves.
    var classificationId: String { get }

    /// Dispatch priority of this classification (lower = higher priority).
    var priority: Int { get }

    /// Stores an event for later batched dispatch.
    func schedule(_ event: CourierEvent)

    /// Starts the periodic ticker that drains and forwards batches.
    func startTicker()

    /// Stops the periodic ticker.
    func stopTicker()

    /// Drains and forwards all currently stored events (used during flushes).
    func drainAll()
}

/// Concrete per-classification scheduler backed by a `CourierEventRepository`.
final class ClassificationCourierEventScheduler: CourierEventScheduling {

    let classificationId: String
    let priority: Int

    private let config: EventClassificationRemoteConfig.ClassificationConfig
    private let repository: CourierEventRepository
    private let batchCreator: CourierEventBatchCreator
    private let performQueue: SerialQueue
    private let ttlEnabled: Bool
    private var timer: DispatchSourceTimer?

    init(config: EventClassificationRemoteConfig.ClassificationConfig,
         repository: CourierEventRepository,
         batchCreator: CourierEventBatchCreator,
         performOnQueue: SerialQueue,
         ttlEnabled: Bool) {
        self.classificationId = config.classificationId
        self.priority = config.priority
        self.config = config
        self.repository = repository
        self.batchCreator = batchCreator
        self.performQueue = performOnQueue
        self.ttlEnabled = ttlEnabled
    }

    func schedule(_ event: CourierEvent) {
        repository.insert(event)
    }

    func startTicker() {
        performQueue.async { [weak self] in
            guard let self else { return }
            self.timer?.cancel()
            let interval = self.config.tickerIntervalSeconds
            guard interval > 0 else { return }
            let timer = DispatchSource.makeTimerSource(flags: .strict, queue: self.performQueue)
            timer.schedule(deadline: .now() + interval, repeating: interval)
            timer.setEventHandler { [weak self] in
                self?.drainOneBatch()
            }
            timer.resume()
            self.timer = timer
        }
    }

    func stopTicker() {
        performQueue.async { [weak self] in
            self?.timer?.cancel()
            self?.timer = nil
        }
    }

    func drainAll() {
        guard batchCreator.canForward else { return }
        while true {
            let events = repository.fetchBatch(limit: config.batchSizeEventCount, ttlEnabled: ttlEnabled)
            guard !events.isEmpty else { break }
            _ = batchCreator.forward(with: events, qos: config.qosLevel)
        }
    }

    private func drainOneBatch() {
        guard batchCreator.canForward else { return }
        let events = repository.fetchBatch(limit: config.batchSizeEventCount, ttlEnabled: ttlEnabled)
        guard !events.isEmpty else { return }
        _ = batchCreator.forward(with: events, qos: config.qosLevel)
    }

    deinit {
        timer?.cancel()
    }
}

/// A no-op scheduler that silently drops events.
///
/// Mirrors the Android `NoOpCourierEventScheduler`, used for inactive classifications so that
/// events resolving to a disabled classification are discarded rather than dispatched.
final class NoOpCourierEventScheduler: CourierEventScheduling {

    let classificationId: String
    let priority: Int

    init(classificationId: String, priority: Int) {
        self.classificationId = classificationId
        self.priority = priority
    }

    func schedule(_ event: CourierEvent) { /* Intentionally dropped. */ }
    func startTicker() { /* No-op. */ }
    func stopTicker() { /* No-op. */ }
    func drainAll() { /* No-op. */ }
}
