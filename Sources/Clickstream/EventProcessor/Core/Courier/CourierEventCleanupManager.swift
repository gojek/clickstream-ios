//
//  CourierEventCleanupManager.swift
//  Clickstream
//
//  Created by Rishab Habbu on 26/05/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

import UIKit

/// Contract for any component responsible for evicting expired `CourierEvent`s from
/// the local persistence store on a periodic schedule.
protocol EventCleanupProtocol {

    /// The DAO holding the persisted `CourierEvent`s that will be evaluated for cleanup.
    var persistence: DefaultDatabaseDAO<CourierEvent> { get }

    /// Starts the underlying scheduler so that cleanup ticks begin firing.
    func schedule()

    /// Stops the underlying scheduler and tears down any active timers.
    func stop()

    /// Wires the eviction logic to the scheduler's tick and starts the schedule.
    func cleanUpExpiredEvents()
}

/// Periodically removes expired `CourierEvent` rows from the persistence layer.
///
/// The cleanup cadence is driven by `EventExpirationConfig.ttlCleanupIntervalInMin`
/// and each tick deletes every row whose `ttl` column is strictly less than `Date()`.
class CourierEventCleanupManager: EventCleanupProtocol {

    /// The DAO whose backing table is scanned for expired rows.
    internal let persistence: DefaultDatabaseDAO<CourierEvent>

    /// TTL configuration that controls the cleanup cadence.
    var cleanupConfiguration: EventExpirationConfig

    init(cleanupConfiguration: EventExpirationConfig, persistence: DefaultDatabaseDAO<CourierEvent>) {
        self.cleanupConfiguration = cleanupConfiguration
        self.persistence = persistence
    }

    /// Dedicated serial queue used by the cleanup timer so it never competes with the
    /// scheduler queue used for outbound event delivery.
    private let cleanupExpiredEventsSchedulerQueue = SerialQueue(label: Constants.QueueIdentifiers.scheduler.rawValue, qos: .utility)

    /// Lazily-built scheduler that fires every `ttlCleanupIntervalInMin` minutes.
    private lazy var expiredEventsCleanupScheduler: SchedulerService = {
        let cleanup_interval = cleanupConfiguration.ttlCleanupIntervalInMin
        let cleanupIntervalSeconds: TimeInterval = Double(cleanup_interval) * 60
        return EventCleanupScheduler(with: Priority(priority: 0, identifier: "cleanup", maxTimeBetweenTwoBatches: cleanupIntervalSeconds), performOnQueue: cleanupExpiredEventsSchedulerQueue)
    }()

    /// Starts the periodic cleanup timer. Safe to call multiple times — the underlying
    /// scheduler resets its timer on each `start()`.
    func schedule() {
        expiredEventsCleanupScheduler.start()
    }

    /// Cancels the periodic cleanup timer.
    func stop() {
        expiredEventsCleanupScheduler.stop()
    }

    /// Attaches the eviction subscriber and starts the scheduler. On every tick,
    /// rows whose `ttl < Date()` are deleted from the persistence store.
    func cleanUpExpiredEvents() {
        self.schedule()
        self.expiredEventsCleanupScheduler.subscriber = { [weak self] _ in
            guard let checkedSelf = self else { return }
            checkedSelf.persistence.deleteWhere(CourierEvent.Columns.ttl, lessThan: Date())
        }
    }
}

/// Repeating dispatch-source-backed scheduler used by `CourierEventCleanupManager`.
///
/// Built on top of `DispatchSourceTimer` and isolated to a single serial queue, so
/// the subscriber callback is delivered serially with respect to other work on that
/// queue.
final class EventCleanupScheduler: SchedulerService {

    private let performQueue: SerialQueue
    private let priority: Priority
    private var timer: DispatchSourceTimer?

    /// Invoked on every timer tick with the configured `Priority`.
    var subscriber: ((Priority) -> ())?

    init(with priority: Priority,
         performOnQueue: SerialQueue) {
        self.priority = priority
        self.performQueue = performOnQueue
    }

    /// Cancels any existing timer and starts a fresh one using `priority.maxTimeBetweenTwoBatches`.
    func start() {
        stop()
        self.timer = makeTimer()
    }

    /// Lower bound (in seconds) for the cleanup timer interval. Guards against a
    /// misconfigured `Priority` (nil or 0 `maxTimeBetweenTwoBatches`) producing a
    /// zero-interval `DispatchSourceTimer` that would saturate the dispatch queue
    /// and hammer the DB writer.
    static let minimumIntervalSeconds: TimeInterval = 60

    /// Builds and resumes a repeating `DispatchSourceTimer`. The configured
    /// interval is clamped to `minimumIntervalSeconds` to prevent a misconfigured
    /// `Priority` from scheduling a tight-loop timer.
    func makeTimer() -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: performQueue)
        let requestedInterval = priority.maxTimeBetweenTwoBatches ?? 0
        let safeInterval = max(requestedInterval, Self.minimumIntervalSeconds)

        timer.schedule(deadline: .now() + safeInterval, repeating: safeInterval)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.subscriber?(self.priority)
        }
        timer.resume()
        return timer
    }

    /// Detaches the event handler and cancels the underlying dispatch source.
    func stop() {
        if let t = timer {
            t.setEventHandler(handler: nil)
            t.cancel()
            timer = nil
        }
    }
}

