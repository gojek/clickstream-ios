//
//  CourierClassificationCoordinator.swift
//  Clickstream
//
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

/// Orchestrates classification-based courier scheduling.
///
/// Active only when `EventClassificationRemoteConfig.Properties.isClassificationEnabled` is true.
/// Replaces the legacy `CourierEventBatchProcessor` driving while preserving the existing
/// instant and P0 fast paths so behaviour for those event types is unchanged.
final class CourierClassificationCoordinator {

    private let config: EventClassificationRemoteConfig.Properties
    private let schedulers: [String: CourierEventScheduling]
    private let defaultScheduler: CourierEventScheduling
    private let batchCreator: CourierEventBatchCreator
    private let persistence: DefaultDatabaseDAO<CourierEvent>
    private let appStateNotifier: AppStateNotifierService
    private let ttlEnabled: Bool

    init(config: EventClassificationRemoteConfig.Properties,
         factory: CourierEventSchedulerFactory,
         batchCreator: CourierEventBatchCreator,
         persistence: DefaultDatabaseDAO<CourierEvent>,
         appStateNotifier: AppStateNotifierService,
         ttlEnabled: Bool) {
        self.config = config
        self.batchCreator = batchCreator
        self.persistence = persistence
        self.appStateNotifier = appStateNotifier
        self.ttlEnabled = ttlEnabled

        let built = factory.createAll(configs: config.configs)
        self.schedulers = built
        let defaultId = EventClassificationRemoteConfig.ClassificationConfig.defaultClassificationId
        self.defaultScheduler = built[defaultId]
            ?? NoOpCourierEventScheduler(classificationId: defaultId, priority: .max)
    }

    func start() {
        schedulers.values.forEach { $0.startTicker() }
        observeAppStateChanges()
    }

    /// Routes a batched event to the scheduler owning its classification.
    func store(_ event: CourierEvent, classificationId: String) {
        (schedulers[classificationId] ?? defaultScheduler).schedule(event)
    }

    /// Forwards an instant event immediately, bypassing batching (current-flow parity).
    func sendInstantly(_ event: CourierEvent) {
        _ = batchCreator.forward(with: [event])
    }

    /// Immediately drains persisted P0 events by classification type (current-flow parity).
    /// The event is expected to already be persisted by the warehouser before this call.
    func sendP0(classificationType: String) {
        guard batchCreator.canForward else { return }

        let events: [CourierEvent]?
        if ttlEnabled {
            events = persistence.deleteWhereNotExpired(CourierEvent.Columns.type, value: classificationType)
        } else {
            events = persistence.deleteWhere(CourierEvent.Columns.type, value: classificationType)
        }

        guard let events, !events.isEmpty else { return }
        _ = batchCreator.forward(with: events)
    }

    func stop() {
        appStateNotifier.stop()
        schedulers.values.forEach { $0.stopTicker() }
    }

    // MARK: - App state

    private func observeAppStateChanges() {
        appStateNotifier.start { [weak self] stateNotification in
            guard let self else { return }
            switch stateNotification {
            case .willTerminate, .didEnterBackground:
                self.flushAll()
            case .willResignActive:
                self.schedulers.values.forEach { $0.stopTicker() }
            case .didBecomeActive:
                self.schedulers.values.forEach { $0.startTicker() }
            case .willEnterForeground:
                break
            }
        }
    }

    /// Drains every classification (priority ascending) and then any remaining persisted events.
    private func flushAll() {
        guard batchCreator.canForward else { return }

        let orderedIds = config.activeConfigsByPriority.map { $0.classificationId }
        var visited = Set<String>()

        for id in orderedIds {
            if let scheduler = schedulers[id] {
                scheduler.drainAll()
                visited.insert(id)
            }
        }

        for (id, scheduler) in schedulers where !visited.contains(id) {
            scheduler.drainAll()
        }

        if let leftovers = persistence.deleteAll(), !leftovers.isEmpty {
            _ = batchCreator.forward(with: leftovers)
        }
    }

    deinit {
        appStateNotifier.stop()
    }
}
