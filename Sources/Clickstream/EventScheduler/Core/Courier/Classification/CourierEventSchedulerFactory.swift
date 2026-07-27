//
//  CourierEventSchedulerFactory.swift
//  Clickstream
//
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

/// Builds the per-classification schedulers from a classification configuration.
///
/// Mirrors the Android `CourierEventSchedulerFactory.createAll`:
/// - active classifications become real schedulers (disk- or memory-backed),
/// - inactive classifications become no-op schedulers (events are dropped),
/// - the default real-time classification is always present.
final class CourierEventSchedulerFactory {

    private let persistence: DefaultDatabaseDAO<CourierEvent>
    private let batchCreator: CourierEventBatchCreator
    private let performQueue: SerialQueue
    private let ttlEnabled: Bool

    init(persistence: DefaultDatabaseDAO<CourierEvent>,
         batchCreator: CourierEventBatchCreator,
         performOnQueue: SerialQueue,
         ttlEnabled: Bool) {
        self.persistence = persistence
        self.batchCreator = batchCreator
        self.performQueue = performOnQueue
        self.ttlEnabled = ttlEnabled
    }

    /// Creates a scheduler for every configured classification, keyed by classification id.
    /// A default real-time scheduler is injected when not provided by the configuration.
    func createAll(configs: [EventClassificationRemoteConfig.ClassificationConfig]) -> [String: CourierEventScheduling] {
        var schedulers: [String: CourierEventScheduling] = [:]

        for config in configs {
            // Only classifications that match something (protos or event names) participate,
            // matching the Android factory which skips empty matchers.
            let hasMatchers = !config.protos.isEmpty || !config.eventNames.isEmpty
            let isDefault = config.classificationId == EventClassificationRemoteConfig.ClassificationConfig.defaultClassificationId
            guard hasMatchers || isDefault else { continue }

            schedulers[config.classificationId] = makeScheduler(for: config)
        }

        let defaultId = EventClassificationRemoteConfig.ClassificationConfig.defaultClassificationId
        if schedulers[defaultId] == nil {
            schedulers[defaultId] = makeScheduler(for: .defaultRealTime())
        }

        return schedulers
    }

    private func makeScheduler(for config: EventClassificationRemoteConfig.ClassificationConfig) -> CourierEventScheduling {
        guard config.isActive else {
            return NoOpCourierEventScheduler(classificationId: config.classificationId, priority: config.priority)
        }

        let repository: CourierEventRepository
        switch config.persistenceType {
        case .memory:
            repository = InMemoryCourierEventRepository()
        case .disk:
            repository = DiskCourierEventRepository(classificationId: config.classificationId,
                                                    persistence: persistence)
        }

        return ClassificationCourierEventScheduler(config: config,
                                                   repository: repository,
                                                   batchCreator: batchCreator,
                                                   performOnQueue: performQueue,
                                                   ttlEnabled: ttlEnabled)
    }
}
