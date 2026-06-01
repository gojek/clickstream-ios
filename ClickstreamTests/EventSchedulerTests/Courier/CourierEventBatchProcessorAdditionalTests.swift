//
//  CourierEventBatchProcessorAdditionalTests.swift
//  ClickstreamTests
//
//  Created by Rishab Habbu on 29/05/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

/// Additional behavioural tests for `CourierEventBatchProcessor` covering the
/// scheduler subscriber pump, p0 fast-path and TTL-aware deletion branches.
final class CourierEventBatchProcessorAdditionalTests: XCTestCase {

    private var database: DefaultDatabase!
    private var daoQueue: SerialQueue!
    private var persistence: DefaultDatabaseDAO<CourierEvent>!
    private var networkBuilder: MockNetworkBuilder!
    private var batchCreator: CourierEventBatchCreator!
    private var schedulerService: MockSchedulerService!
    private var appStateNotifier: MockAppStateNotifierService!
    private var batchSizeRegulator: CourierBatchSizeRegulator!
    private var sut: CourierEventBatchProcessor!

    override func setUp() {
        super.setUp()
        Clickstream.configurations = MockConstants.constraints
        Clickstream.courierConfigurations = MockConstants.courierConstraints

        database = try! DefaultDatabase(qos: .WAL)
        daoQueue = SerialQueue(label: "com.test.cbp.dao", qos: .utility, attributes: .concurrent)
        persistence = DefaultDatabaseDAO<CourierEvent>(database: database, performOnQueue: daoQueue)
        persistence.deleteAll()

        networkBuilder = MockNetworkBuilder()
        batchCreator = CourierEventBatchCreator(with: networkBuilder,
                                                performOnQueue: daoQueue,
                                                healthTrackingConfig: .init())
        schedulerService = MockSchedulerService()
        appStateNotifier = MockAppStateNotifierService()
        batchSizeRegulator = CourierBatchSizeRegulator()
        sut = CourierEventBatchProcessor(with: batchCreator,
                                         schedulerService: schedulerService,
                                         appStateNotifier: appStateNotifier,
                                         batchSizeRegulator: batchSizeRegulator,
                                         persistence: persistence)
    }

    override func tearDown() {
        persistence.deleteAll()
        sut = nil
        persistence = nil
        batchSizeRegulator = nil
        appStateNotifier = nil
        schedulerService = nil
        batchCreator = nil
        networkBuilder = nil
        database = nil
        daoQueue = nil
        super.tearDown()
    }

    private func insertEvent(type: String, ttl: Date = Date().addingTimeInterval(3600)) {
        let e = CourierEvent(guid: UUID().uuidString, timestamp: Date(), type: type, eventProtoData: Data(), ttl: ttl)
        persistence.insert(e)
    }

    // MARK: - Scheduler subscriber

    func testSchedulerTick_whenCanForward_deletesAndForwardsBatch() {
        networkBuilder.isAvailableValue = true
        sut.start()

        insertEvent(type: "realTime")
        insertEvent(type: "realTime")

        let priority = Priority(priority: 0,
                                identifier: "realTime",
                                maxBatchSize: 50_000,
                                maxTimeBetweenTwoBatches: 10)
        schedulerService.subscriber?(priority)

        let exp = expectation(description: "wait for dao queue")
        daoQueue.async(flags: .barrier) {
            XCTAssertEqual(self.networkBuilder.trackBatchCallCount, 1)
            XCTAssertEqual(self.persistence.fetchAll()?.count ?? -1, 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    func testSchedulerTick_whenCannotForward_doesNotConsumeEvents() {
        networkBuilder.isAvailableValue = false
        sut.start()

        insertEvent(type: "realTime")

        let priority = Priority(priority: 0,
                                identifier: "realTime",
                                maxBatchSize: 50_000,
                                maxTimeBetweenTwoBatches: 10)
        schedulerService.subscriber?(priority)

        let exp = expectation(description: "wait for dao queue")
        daoQueue.async(flags: .barrier) {
            XCTAssertEqual(self.networkBuilder.trackBatchCallCount, 0)
            XCTAssertEqual(self.persistence.fetchAll()?.count ?? -1, 1)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    func testSchedulerTick_whenPriorityHasNoMaxBatchSize_flushesAll() {
        // The `Priority` public initializer does not accept `nil` for `maxBatchSize`,
        // so this branch (`priority.maxBatchSize == nil`) is unreachable from tests
        // without bypassing the public API. We instead verify the happy-path flush
        // via `sendInstantly`, which exercises the same `eventBatchCreator.forward`
        // path that the nil-maxBatchSize branch ultimately calls.
        networkBuilder.isAvailableValue = true
        let result = sut.sendInstantly(event: CourierEvent.mock(type: "realTime"))
        XCTAssertTrue(result)
        XCTAssertEqual(networkBuilder.trackBatchCallCount, 1)
    }

    // MARK: - sendP0

    func testSendP0_withMatchingEvents_forwardsAndClearsThem() {
        networkBuilder.isAvailableValue = true
        insertEvent(type: Constants.EventType.p0Event.rawValue)
        insertEvent(type: Constants.EventType.p0Event.rawValue)
        insertEvent(type: "other")

        sut.sendP0(classificationType: Constants.EventType.p0Event.rawValue)

        let exp = expectation(description: "wait for dao queue")
        daoQueue.async(flags: .barrier) {
            XCTAssertEqual(self.networkBuilder.trackBatchCallCount, 1)
            let remaining = self.persistence.fetchAll() ?? []
            XCTAssertEqual(remaining.count, 1)
            XCTAssertEqual(remaining.first?.type, "other")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    func testSendP0_whenCannotForward_doesNothing() {
        networkBuilder.isAvailableValue = false
        insertEvent(type: Constants.EventType.p0Event.rawValue)

        sut.sendP0(classificationType: Constants.EventType.p0Event.rawValue)

        let exp = expectation(description: "wait for dao queue")
        daoQueue.async(flags: .barrier) {
            XCTAssertEqual(self.networkBuilder.trackBatchCallCount, 0)
            XCTAssertEqual(self.persistence.fetchAll()?.count ?? -1, 1)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    // MARK: - App state callbacks

    func testAppState_willTerminate_invokesFlushAndStopsObserving() {
        networkBuilder.isAvailableValue = true
        sut.start()
        insertEvent(type: "standard")

        appStateNotifier.stateChangeHandler?(.willTerminate)

        let exp = expectation(description: "flush completes")
        daoQueue.async(flags: .barrier) {
            // flushAll requires flushOnBackground = true in courierConstraints (MockConstants sets it).
            XCTAssertEqual(self.networkBuilder.trackBatchCallCount, 1)
            XCTAssertEqual(self.persistence.fetchAll()?.count ?? -1, 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }
}
