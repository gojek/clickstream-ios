//
//  EventExpiryManager.swift
//  Clickstream
//
//  Created by Rishab Habbu on 26/05/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

import Foundation

/// Contract for any component capable of computing a `CourierEvent`'s TTL.
protocol EventExpirationProtocol {
    /// Default expiration applied when no event-specific override exists.
    func getDefaultExpiration() -> Date
    /// Expiration for a specific event. Falls back to `getDefaultExpiration()` when no
    /// per-event override applies.
    func getExpiration(for event: ClickstreamEvent) -> Date
}

/// Configurable expiry resolver driven by `EventExpirationConfig`.
///
/// Resolution order:
/// 1. If `eventsTTL` contains an entry keyed by `event.csEventName`, that override is used.
/// 2. Otherwise the configured `defaultExpiryDays` value is added to "now".
class EventExpiryManager: EventExpirationProtocol {

    /// Backing configuration loaded from remote / config layer.
    let eventExpiryConfig: EventExpirationConfig

    init(eventExpiryConfig: EventExpirationConfig) {
        self.eventExpiryConfig = eventExpiryConfig
    }

    /// `Date()` advanced by `defaultExpiryDays`.
    func getDefaultExpiration() -> Date {
        let default_ttl = calculateMinimumExpiryDays(for: eventExpiryConfig.defaultExpiryDays)
        let date = Date().addingDays(default_ttl)
        return date
    }

    /// Resolves the TTL for `event`, honoring per-event overrides when available.
    func getExpiration(for event: ClickstreamEvent) -> Date {
        guard !eventExpiryConfig.eventsTTL.isEmpty, let csEventName = event.csEventName else {
            return getDefaultExpiration()
        }

        if let ttl = eventExpiryConfig.eventsTTL[csEventName] {
            let date = Date().addingDays(calculateMinimumExpiryDays(for: ttl))
            return date
        }

        return getDefaultExpiration()
    }
    
    /// Calculate the minimum days
    func calculateMinimumExpiryDays(for days: Int) -> Int {
        let minimumExpiryDays = eventExpiryConfig.minimumExpiryDays
        if days < minimumExpiryDays {
            return minimumExpiryDays
        }
        return days
    }
}

/// Safety-net implementation used when no TTL configuration is supplied.
/// Defaults every event to live for ~6 months (using a fixed 30-day month).
class FallbackEventExpirationManager: EventExpirationProtocol {

    func getDefaultExpiration() -> Date {
        return Date().addingMonthsWith30days(2)
    }

    func getExpiration(for event: ClickstreamEvent) -> Date {
        return getDefaultExpiration()
    }
}

extension Date {
    /// Returns a date offset from `self` by the given number of calendar-agnostic days
    /// (each day == 86_400 seconds; no DST adjustment).
    func addingDays(_ days: Int) -> Date {
        return self.addingTimeInterval(TimeInterval(days) * 60 * 60 * 24)
    }

    /// Returns a date offset from `self` by the given number of fixed 30-day months.
    /// Intended only for coarse TTL math, not calendar-accurate month arithmetic.
    func addingMonthsWith30days(_ months: Int) -> Date {
        return self.addingTimeInterval(TimeInterval(months) * 60 * 60 * 24 * 30)
    }
}
