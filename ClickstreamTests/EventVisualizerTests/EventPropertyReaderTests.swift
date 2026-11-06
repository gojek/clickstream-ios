//
//  EventPropertyReaderTests.swift
//  ClickstreamTests
//
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import SwiftProtobuf
import XCTest

final class EventPropertyReaderTests: XCTestCase {

    func testEntriesReturnsEmptyForNilMessage() {
        XCTAssertTrue(EventPropertyReader.entries(from: nil).isEmpty)
    }

    func testEntriesReturnsEmptyForMessageWithoutCollectionMapper() {
        XCTAssertTrue(EventPropertyReader.entries(from: Google_Protobuf_Duration()).isEmpty)
    }

    func testEntriesAreSortedByKeyPath() {
        let event = EventVisualizerTestFixtures.makeEvent(name: "Order Placed", numberOfEvents: 3)

        let keys = EventPropertyReader.entries(from: event.msg).map { $0.0 }

        XCTAssertEqual(keys, keys.sorted())
        XCTAssertTrue(keys.contains("eventName"))
        XCTAssertTrue(keys.contains("numberOfEvents"))
    }

    func testEntriesExposeValues() {
        let event = EventVisualizerTestFixtures.makeEvent(name: "Order Placed", numberOfEvents: 3)

        let entries = Dictionary(uniqueKeysWithValues: EventPropertyReader.entries(from: event.msg).map { ($0.0, "\($0.1)") })

        XCTAssertEqual(entries["eventName"], "Order Placed")
        XCTAssertEqual(entries["numberOfEvents"], "3")
    }

    func testEntriesDropEmptyStringValues() {
        let event = EventVisualizerTestFixtures.makeEvent(name: "")

        let keys = EventPropertyReader.entries(from: event.msg).map { $0.0 }

        XCTAssertFalse(keys.contains("eventName"))
    }
}
