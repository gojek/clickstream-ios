//
//  CourierEventRepository.swift
//  Clickstream
//
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

/// Storage abstraction for events belonging to a single courier classification.
///
/// Mirrors the Android `CourierEventRepository` contract. iOS fetch semantics are
/// fetch-and-remove: returned events are deleted from the backing store, matching the
/// existing courier scheduler behaviour.
protocol CourierEventRepository {

    /// Persists an event for later batch dispatch.
    func insert(_ event: CourierEvent)

    /// Fetches up to `limit` events and removes them from the store.
    /// - Parameters:
    ///   - limit: Maximum number of events to fetch. `0` fetches all available events.
    ///   - ttlEnabled: When true, expired events are skipped (and pruned) by the store.
    /// - Returns: The fetched events, or an empty array when none are available.
    func fetchBatch(limit: Int, ttlEnabled: Bool) -> [CourierEvent]
}

/// Disk-backed repository scoped to one classification, layered over the shared courier DAO.
///
/// Events are routed by `CourierEvent.type`, which carries the classification identifier.
final class DiskCourierEventRepository: CourierEventRepository {

    private let classificationId: String
    private let persistence: DefaultDatabaseDAO<CourierEvent>

    init(classificationId: String, persistence: DefaultDatabaseDAO<CourierEvent>) {
        self.classificationId = classificationId
        self.persistence = persistence
    }

    func insert(_ event: CourierEvent) {
        persistence.insert(event)
    }

    func fetchBatch(limit: Int, ttlEnabled: Bool) -> [CourierEvent] {
        let events: [CourierEvent]?
        if ttlEnabled {
            events = persistence.deleteWhereNotExpired(CourierEvent.Columns.type,
                                                       value: classificationId,
                                                       n: limit)
        } else {
            events = persistence.deleteWhere(CourierEvent.Columns.type,
                                             value: classificationId,
                                             n: limit)
        }
        return events ?? []
    }
}

/// In-memory repository scoped to one classification.
///
/// Mirrors the Android `InMemoryCourierEventRepository`: a thread-safe map keyed by event GUID,
/// holding events only for the lifetime of the process. Used for `MEMORY` persistence
/// classifications where durability across restarts is not required.
final class InMemoryCourierEventRepository: CourierEventRepository {

    private let accessQueue = DispatchQueue(label: "com.clickstream.courier.classification.memstore",
                                            attributes: .concurrent)
    private var storage: [String: CourierEvent] = [:]
    private let ttlEnabledOverride: Bool

    init(ttlEnabledOverride: Bool = true) {
        self.ttlEnabledOverride = ttlEnabledOverride
    }

    func insert(_ event: CourierEvent) {
        accessQueue.sync(flags: .barrier) {
            storage[event.guid] = event
        }
    }

    func fetchBatch(limit: Int, ttlEnabled: Bool) -> [CourierEvent] {
        accessQueue.sync(flags: .barrier) {
            let now = Date()
            let applyTTL = ttlEnabled && ttlEnabledOverride

            if applyTTL {
                storage = storage.filter { $0.value.expiryTime > now }
            }

            let ordered = storage.values.sorted { $0.timestamp < $1.timestamp }
            let slice: [CourierEvent]
            if limit > 0 {
                slice = Array(ordered.prefix(limit))
            } else {
                slice = ordered
            }

            for event in slice {
                storage.removeValue(forKey: event.guid)
            }
            return slice
        }
    }
}
