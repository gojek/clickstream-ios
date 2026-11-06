//
//  EventsPinnedPropertiesStoreTests.swift
//  ClickstreamTests
//
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

final class EventsPinnedPropertiesStoreTests: XCTestCase {

    private let helper = EventsHelper.shared
    private var defaults: UserDefaults!
    private var store: EventsPinnedPropertiesStore!

    private let orderCount = EventsPinnedProperty(eventName: "Order Placed", keyPath: "numberOfEvents")
    private let orderName = EventsPinnedProperty(eventName: "Order Placed", keyPath: "eventName")

    override func setUp() {
        super.setUp()
        helper.clearData()
        defaults = EventVisualizerTestFixtures.makeDefaults()
        store = EventsPinnedPropertiesStore(defaults: defaults, helper: helper)
    }

    override func tearDown() {
        helper.clearData()
        store = nil
        defaults = nil
        super.tearDown()
    }

    // MARK: - Pins

    func testAddAppendsPinOnce() {
        store.add(orderCount)
        store.add(orderCount)

        XCTAssertEqual(store.pins, [orderCount])
        XCTAssertTrue(store.contains(orderCount))
    }

    func testRemoveDeletesOnlyThatPin() {
        store.add(orderCount)
        store.add(orderName)

        store.remove(orderCount)

        XCTAssertEqual(store.pins, [orderName])
    }

    func testRemoveAllClearsPins() {
        store.add(orderCount)
        store.add(orderName)

        store.removeAll()

        XCTAssertTrue(store.pins.isEmpty)
    }

    func testToggleAddsThenRemoves() {
        store.toggle(orderCount)
        XCTAssertTrue(store.contains(orderCount))

        store.toggle(orderCount)
        XCTAssertFalse(store.contains(orderCount))
    }

    func testPinsPersistAcrossInstancesInOrder() {
        store.add(orderName)
        store.add(orderCount)

        let reloaded = EventsPinnedPropertiesStore(defaults: defaults, helper: helper)

        XCTAssertEqual(reloaded.pins, [orderName, orderCount])
    }

    func testRemovalPersists() {
        store.add(orderCount)
        store.removeAll()

        let reloaded = EventsPinnedPropertiesStore(defaults: defaults, helper: helper)

        XCTAssertTrue(reloaded.pins.isEmpty)
    }

    func testCorruptStoredDataLoadsAsNoPins() {
        defaults.set(Data("not json".utf8), forKey: "eventsVisualizerPinnedProperties")

        let reloaded = EventsPinnedPropertiesStore(defaults: defaults, helper: helper)

        XCTAssertTrue(reloaded.pins.isEmpty)
    }

    // MARK: - Notifications

    func testAddPostsDidChangeOnMainThread() {
        let posted = expectation(forNotification: EventsPinnedPropertiesStore.didChangeNotification, object: store) { _ in
            Thread.isMainThread
        }

        store.add(orderCount)

        wait(for: [posted], timeout: 1)
    }

    func testNoOpChangesDoNotPostDidChange() {
        let notPosted = expectation(forNotification: EventsPinnedPropertiesStore.didChangeNotification, object: store)
        notPosted.isInverted = true

        store.remove(orderCount)
        store.removeAll()

        wait(for: [notPosted], timeout: 0.3)
    }

    // MARK: - Values

    func testCurrentValuesIsEmptyWithoutPins() {
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "Order Placed"))

        XCTAssertTrue(store.currentValues().isEmpty)
    }

    func testCurrentValueIsPlaceholderBeforeEventIsCaptured() {
        store.add(orderCount)

        XCTAssertEqual(store.currentValues(), [EventsPinnedValue(pin: orderCount, value: EventsPinnedPropertiesStore.emptyValue)])
    }

    func testCurrentValueIsPlaceholderForUnknownKeyPath() {
        let unknown = EventsPinnedProperty(eventName: "Order Placed", keyPath: "doesNotExist")
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "Order Placed"))
        store.add(unknown)

        XCTAssertEqual(store.currentValues().first?.value, EventsPinnedPropertiesStore.emptyValue)
    }

    func testCurrentValueTracksLatestCapturedEvent() {
        store.add(orderCount)
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "Order Placed", numberOfEvents: 1))
        XCTAssertEqual(store.currentValues().first?.value, "1")

        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "Order Placed", numberOfEvents: 7))
        XCTAssertEqual(store.currentValues().first?.value, "7")
    }

    func testCurrentValuesKeepPinOrderAcrossEvents() {
        let other = EventsPinnedProperty(eventName: "Other", keyPath: "numberOfEvents")
        store.add(other)
        store.add(orderCount)
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "Order Placed", numberOfEvents: 2))
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "Other", numberOfEvents: 9))

        XCTAssertEqual(store.currentValues().map(\.pin), [other, orderCount])
        XCTAssertEqual(store.currentValues().map(\.value), ["9", "2"])
    }

    func testCurrentValuesIsEmptyAfterClearDataButPinsRemain() {
        store.add(orderCount)
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "Order Placed", numberOfEvents: 5))

        helper.clearData()

        XCTAssertEqual(store.currentValues().first?.value, EventsPinnedPropertiesStore.emptyValue)
        XCTAssertEqual(store.pins, [orderCount])
    }

    func testLatestEventNamedReturnsMostRecent() {
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "Order Placed", numberOfEvents: 1))
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "Order Placed", numberOfEvents: 4))

        let event = store.latestEvent(named: "Order Placed")

        XCTAssertEqual((event?.msg as? Gojek_Clickstream_Internal_Health)?.numberOfEvents, 4)
        XCTAssertNil(store.latestEvent(named: "Missing"))
    }
}
