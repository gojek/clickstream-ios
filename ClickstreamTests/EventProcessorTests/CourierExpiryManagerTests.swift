//
//  CourierExpiryManagerTests.swift
//  ClickstreamTests
//
//  Created by Rishab Habbu on 29/05/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

final class CourierExpiryManagerTests: XCTestCase {

    private let secondsPerDay: TimeInterval = 60 * 60 * 24
    private let secondsPer30DayMonth: TimeInterval = 60 * 60 * 24 * 30

    // MARK: - EventExpirationConfig helper

    /// Builds an `EventExpirationConfig` via JSON decoding since it has no memberwise init.
    private func makeConfig(defaultExpiryDays: Int = 7,
                            eventsTTL: [String: Int] = [:]) throws -> EventExpirationConfig {
        let payload: [String: Any] = [
            "is_ttl_enabled": true,
            "default_expiry_days": defaultExpiryDays,
            "minimum_expiry_days": 1,
            "events_ttl": eventsTTL,
            "is_ttl_cleanup_enabled": true,
            "ttl_cleanup_interval_in_min": 30,
            "ttl_periodic_backOff_policy": "NONE",
            "ttl_periodic_backOff_delay_in_min": 0
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try JSONDecoder().decode(EventExpirationConfig.self, from: data)
    }

    private func makeEvent(csEventName: String? = nil) -> ClickstreamEvent {
        ClickstreamEvent(guid: UUID().uuidString,
                         timeStamp: Date(),
                         message: nil,
                         eventName: "test.event.name",
                         eventData: Data(),
                         csEventName: csEventName,
                         product: "CSTestProduct")
    }

    // MARK: - EventExpiryManager

    func testDefaultExpiration_appliesConfiguredDefaultExpiryDays() throws {
        let config = try makeConfig(defaultExpiryDays: 3)
        let sut = EventExpiryManager(eventExpiryConfig: config)

        let before = Date()
        let expiry = sut.getDefaultExpiration()
        let after = Date()

        XCTAssertGreaterThanOrEqual(expiry.timeIntervalSince(before), 3 * secondsPerDay - 1)
        XCTAssertLessThanOrEqual(expiry.timeIntervalSince(after), 3 * secondsPerDay + 1)
    }

    func testExpirationForEvent_returnsDefault_whenEventsTTLIsEmpty() throws {
        let config = try makeConfig(defaultExpiryDays: 5, eventsTTL: [:])
        let sut = EventExpiryManager(eventExpiryConfig: config)

        let event = makeEvent(csEventName: "EventA")
        let expiry = sut.getExpiration(for: event)

        XCTAssertEqual(expiry.timeIntervalSinceNow, 5 * secondsPerDay, accuracy: 1)
    }

    func testExpirationForEvent_returnsDefault_whenCsEventNameIsNil() throws {
        let config = try makeConfig(defaultExpiryDays: 10, eventsTTL: ["EventA": 1])
        let sut = EventExpiryManager(eventExpiryConfig: config)

        let event = makeEvent(csEventName: nil)
        let expiry = sut.getExpiration(for: event)

        XCTAssertEqual(expiry.timeIntervalSinceNow, 10 * secondsPerDay, accuracy: 1)
    }

    func testExpirationForEvent_returnsDefault_whenCsEventNameNotInDictionary() throws {
        let config = try makeConfig(defaultExpiryDays: 4, eventsTTL: ["EventA": 1])
        let sut = EventExpiryManager(eventExpiryConfig: config)

        let event = makeEvent(csEventName: "EventB")
        let expiry = sut.getExpiration(for: event)

        XCTAssertEqual(expiry.timeIntervalSinceNow, 4 * secondsPerDay, accuracy: 1)
    }

    func testExpirationForEvent_returnsPerEventOverride_whenPresent() throws {
        let config = try makeConfig(defaultExpiryDays: 30, eventsTTL: ["EventA": 2])
        let sut = EventExpiryManager(eventExpiryConfig: config)

        let event = makeEvent(csEventName: "EventA")
        let expiry = sut.getExpiration(for: event)

        XCTAssertEqual(expiry.timeIntervalSinceNow, 2 * secondsPerDay, accuracy: 1)
    }

    func testExpirationForEvent_zeroDefaultExpiry_returnsApproximatelyNow() throws {
        let config = try makeConfig(defaultExpiryDays: 0, eventsTTL: [:])
        let sut = EventExpiryManager(eventExpiryConfig: config)

        let expiry = sut.getDefaultExpiration()
        XCTAssertEqual(expiry.timeIntervalSinceNow, 0, accuracy: 1)
    }

    // MARK: - FallbackEventExpirationManager

    func testFallbackDefaultExpiration_isApproximately6MonthsFromNow() {
        let sut = FallbackEventExpirationManager()
        let expiry = sut.getDefaultExpiration()

        XCTAssertEqual(expiry.timeIntervalSinceNow, 6 * secondsPer30DayMonth, accuracy: 2)
    }

    func testFallbackExpirationForEvent_returnsDefault_regardlessOfCsEventName() {
        let sut = FallbackEventExpirationManager()
        let event = makeEvent(csEventName: "EventA")

        let expiry = sut.getExpiration(for: event)

        XCTAssertEqual(expiry.timeIntervalSinceNow, 6 * secondsPer30DayMonth, accuracy: 2)
    }

    // MARK: - Date helpers

    func testAddingDays_zero_returnsSameInstant() {
        let now = Date()
        XCTAssertEqual(now.addingDays(0).timeIntervalSince(now), 0, accuracy: 0.0001)
    }

    func testAddingDays_positive_movesForward() {
        let now = Date()
        XCTAssertEqual(now.addingDays(3).timeIntervalSince(now), 3 * secondsPerDay, accuracy: 0.0001)
    }

    func testAddingDays_negative_movesBackward() {
        let now = Date()
        XCTAssertEqual(now.addingDays(-2).timeIntervalSince(now), -2 * secondsPerDay, accuracy: 0.0001)
    }

    func testAddingMonthsWith30Days_movesByFixed30DayMonths() {
        let now = Date()
        XCTAssertEqual(now.addingMonthsWith30days(2).timeIntervalSince(now),
                       2 * secondsPer30DayMonth,
                       accuracy: 0.0001)
    }
}
