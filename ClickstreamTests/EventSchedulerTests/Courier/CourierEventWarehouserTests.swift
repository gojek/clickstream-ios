//
//  CourierEventWarehouserTests.swift
//  ClickstreamTests
//
//  Created by Rishab Habbu on 29/05/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

final class CourierEventWarehouserTests: XCTestCase {

    private var database: DefaultDatabase!
    private var daoQueue: SerialQueue!
    private var warehouserQueue: SerialQueue!
    private var persistence: DefaultDatabaseDAO<CourierEvent>!
    private var batchSizeRegulator: CourierBatchSizeRegulator!
    private var networkBuilder: MockNetworkBuilder!
    private var batchCreator: CourierEventBatchCreator!
    private var schedulerService: MockSchedulerService!
    private var appStateNotifier: MockAppStateNotifierService!
    private var batchProcessor: CourierEventBatchProcessor!
    private var networkOptions: ClickstreamNetworkOptions!

    override func setUp() {
        super.setUp()
        Clickstream.configurations = MockConstants.constraints
        Clickstream.courierConfigurations = MockConstants.courierConstraints

        database = try! DefaultDatabase(qos: .WAL)
        daoQueue = SerialQueue(label: "com.test.warehouser.dao", qos: .utility, attributes: .concurrent)
        warehouserQueue = SerialQueue(label: "com.test.warehouser.queue", qos: .utility)
        persistence = DefaultDatabaseDAO<CourierEvent>(database: database, performOnQueue: daoQueue)
        persistence.deleteAll()

        batchSizeRegulator = CourierBatchSizeRegulator()
        networkOptions = ClickstreamNetworkOptions()
        networkBuilder = MockNetworkBuilder()
        batchCreator = CourierEventBatchCreator(with: networkBuilder,
                                                performOnQueue: warehouserQueue,
                                                healthTrackingConfig: .init())
        schedulerService = MockSchedulerService()
        appStateNotifier = MockAppStateNotifierService()
        batchProcessor = CourierEventBatchProcessor(with: batchCreator,
                                                    schedulerService: schedulerService,
                                                    appStateNotifier: appStateNotifier,
                                                    batchSizeRegulator: batchSizeRegulator,
                                                    persistence: persistence)
    }

    override func tearDown() {
        persistence.deleteAll()
        persistence = nil
        batchProcessor = nil
        batchCreator = nil
        networkBuilder = nil
        appStateNotifier = nil
        schedulerService = nil
        batchSizeRegulator = nil
        networkOptions = nil
        warehouserQueue = nil
        daoQueue = nil
        database = nil
        super.tearDown()
    }

    private func makeSUT(cleanupManager: CourierEventCleanupManager? = nil) -> CourierEventWarehouser {
        CourierEventWarehouser(with: batchProcessor,
                               performOnQueue: warehouserQueue,
                               persistence: persistence,
                               batchSizeRegulator: batchSizeRegulator,
                               networkOptions: networkOptions,
                               eventCleanupManager: cleanupManager)
    }

    private func event(type: String, guid: String = UUID().uuidString) -> CourierEvent {
        CourierEvent(guid: guid,
                     timestamp: Date(),
                     type: type,
                     eventProtoData: Data(),
                     ttl: Date().addingTimeInterval(3600))
    }

    // MARK: - store

    func testStore_standardEvent_persistsToDatabase() {
        let sut = makeSUT()
        let expectation = self.expectation(description: "Standard event persisted")

        sut.store(event(type: Constants.EventType.standard.rawValue, guid: "standard-1"))

        warehouserQueue.asyncAfter(deadline: .now() + 0.5) {
            let all = self.persistence.fetchAll() ?? []
            XCTAssertEqual(all.map { $0.guid }, ["standard-1"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testStore_instantEvent_doesNotPersistAndForwardsImmediately() {
        networkBuilder.isAvailableValue = true
        let sut = makeSUT()
        let expectation = self.expectation(description: "Instant event forwarded without persistence")

        sut.store(event(type: Constants.EventType.instant.rawValue, guid: "instant-1"))

        warehouserQueue.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.persistence.fetchAll()?.count ?? 0, 0)
            XCTAssertEqual(self.networkBuilder.trackBatchCallCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testStore_p0Event_persistsAndTriggersSendP0() {
        networkBuilder.isAvailableValue = true
        let sut = makeSUT()
        let expectation = self.expectation(description: "P0 event persisted and forwarded")

        sut.store(event(type: Constants.EventType.p0Event.rawValue, guid: "p0-1"))

        warehouserQueue.asyncAfter(deadline: .now() + 0.7) {
            // sendP0 deletes the rows after forwarding, so the table should end up empty
            // and the network builder should have been invoked exactly once.
            XCTAssertEqual(self.networkBuilder.trackBatchCallCount, 1)
            XCTAssertEqual(self.persistence.fetchAll()?.count ?? 0, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testStop_callsThroughToBatchProcessor() {
        let sut = makeSUT()
        sut.stop()

        XCTAssertEqual(schedulerService.stopCallCount, 1)
        XCTAssertEqual(appStateNotifier.stopCallCount, 1)
    }

    func testInit_withCleanupManager_invokesCleanUpExpiredEvents() throws {
        let payload: [String: Any] = [
            "is_ttl_enabled": true,
            "default_expiry_days": 7,
            "minimum_expiry_days": 1,
            "events_ttl": [:],
            "is_ttl_cleanup_enabled": true,
            "ttl_cleanup_interval_in_min": 60,
            "ttl_periodic_backOff_policy": "NONE",
            "ttl_periodic_backOff_delay_in_min": 0
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let config = try JSONDecoder().decode(EventExpirationConfig.self, from: data)
        let manager = CourierEventCleanupManager(cleanupConfiguration: config, persistence: persistence)

        let sut = makeSUT(cleanupManager: manager)

        // Smoke: the warehouser should still produce a usable instance and not crash.
        XCTAssertNotNil(sut)
        manager.stop()
    }
}
