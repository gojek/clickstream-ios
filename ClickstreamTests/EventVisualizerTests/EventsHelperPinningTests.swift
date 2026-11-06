//
//  EventsHelperPinningTests.swift
//  ClickstreamTests
//
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

final class EventsHelperPinningTests: XCTestCase {

    private let helper = EventsHelper.shared

    override func setUp() {
        super.setUp()
        helper.stopCapturing()
        helper.clearData()
    }

    override func tearDown() {
        helper.stopCapturing()
        helper.clearData()
        super.tearDown()
    }

    // MARK: - Capturing

    func testStartCapturingWorksWithoutAClickstreamInstance() {
        Clickstream.destroy()
        XCTAssertNil(Clickstream.getInstance())

        helper.startCapturing()

        XCTAssertTrue(helper.isCapturing, "startCapturing must not depend on Clickstream.initialise having run")
    }

    func testStopCapturingClearsCapturingState() {
        helper.startCapturing()

        helper.stopCapturing()

        XCTAssertFalse(helper.isCapturing)
    }

    func testStopCapturingDoesNotUnregisterAnotherViewer() {
        let other = OtherStateViewer()
        Clickstream._stateViewer = other
        defer { Clickstream._stateViewer = nil }

        helper.stopCapturing()

        XCTAssertTrue(Clickstream._stateViewer === other)
    }

    // MARK: - Notifications

    func testSendEventPostsDidChange() {
        let posted = expectation(forNotification: EventsHelper.didChangeNotification, object: helper)

        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "A"))

        wait(for: [posted], timeout: 1)
    }

    func testUpdateStatusPostsDidChange() {
        let posted = expectation(forNotification: EventsHelper.didChangeNotification, object: helper)

        helper.updateStatus(providedEventGuid: "missing", state: .sent)

        wait(for: [posted], timeout: 1)
    }

    func testClearDataPostsDidChange() {
        let posted = expectation(forNotification: EventsHelper.didChangeNotification, object: helper)

        helper.clearData()

        wait(for: [posted], timeout: 1)
    }

    func testStartAndStopCapturingPostDidChange() {
        let posted = expectation(forNotification: EventsHelper.didChangeNotification, object: helper)
        posted.expectedFulfillmentCount = 2

        helper.startCapturing()
        helper.stopCapturing()

        wait(for: [posted], timeout: 1)
    }

    // MARK: - Lookups

    func testLatestEventsReturnsMostRecentPerName() {
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "A", numberOfEvents: 1))
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "B", numberOfEvents: 2))
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "A", numberOfEvents: 3))

        let latest = helper.latestEvents(named: ["A", "B", "C"])

        XCTAssertEqual(Set(latest.keys), ["A", "B"])
        XCTAssertEqual((latest["A"]?.msg as? Gojek_Clickstream_Internal_Health)?.numberOfEvents, 3)
        XCTAssertEqual((latest["B"]?.msg as? Gojek_Clickstream_Internal_Health)?.numberOfEvents, 2)
    }

    func testLatestEventsWithNoNamesIsEmpty() {
        helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: "A"))

        XCTAssertTrue(helper.latestEvents(named: []).isEmpty)
    }

    func testCapturedEventNamesAreDistinctAndSorted() {
        ["b", "a", "b", "c"].forEach { helper.sendEvent(EventVisualizerTestFixtures.makeEvent(name: $0)) }

        XCTAssertEqual(helper.capturedEventNames(), ["a", "b", "c"])
    }
}

private final class OtherStateViewer: EventStateViewable {
    func sendEvent(_ event: EventData) {}
    func updateStatus(providedEventGuid: String?, eventBatchID: String?, state: EventState) {}
}
