//
//  CourierEventProcessorAdditionalTests.swift
//  ClickstreamTests
//
//  Created by Rishab Habbu on 29/05/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

/// Additional coverage for `CourierEventProcessor` focused on the sampling /
/// classification / TTL-construction branches that the existing test file does
/// not exercise.
final class CourierEventProcessorAdditionalTests: XCTestCase {

    private var queue: SerialQueue!
    private var classifier: MockEventClassifier!
    private var networkBuilder: MockNetworkBuilder!
    private var batchCreator: CourierEventBatchCreator!
    private var schedulerService: MockSchedulerService!
    private var appStateNotifier: MockAppStateNotifierService!
    private var batchSizeRegulator: CourierBatchSizeRegulator!
    private var persistence: DefaultDatabaseDAO<CourierEvent>!
    private var batchProcessor: CourierEventBatchProcessor!
    private var warehouser: CourierEventWarehouser!
    private var database: DefaultDatabase!

    override func setUp() {
        super.setUp()
        Clickstream.configurations = MockConstants.constraints
        Clickstream.courierConfigurations = MockConstants.courierConstraints

        queue = SerialQueue(label: "com.test.cep.queue", qos: .utility)
        database = try! DefaultDatabase(qos: .WAL)
        persistence = DefaultDatabaseDAO<CourierEvent>(database: database, performOnQueue: queue)
        persistence.deleteAll()
        classifier = MockEventClassifier()
        classifier.classificationResult = "realTime"

        networkBuilder = MockNetworkBuilder()
        batchCreator = CourierEventBatchCreator(with: networkBuilder,
                                                performOnQueue: queue,
                                                healthTrackingConfig: .init())
        schedulerService = MockSchedulerService()
        appStateNotifier = MockAppStateNotifierService()
        batchSizeRegulator = CourierBatchSizeRegulator()
        batchProcessor = CourierEventBatchProcessor(with: batchCreator,
                                                    schedulerService: schedulerService,
                                                    appStateNotifier: appStateNotifier,
                                                    batchSizeRegulator: batchSizeRegulator,
                                                    persistence: persistence)
        warehouser = CourierEventWarehouser(with: batchProcessor,
                                            performOnQueue: queue,
                                            persistence: persistence,
                                            batchSizeRegulator: batchSizeRegulator,
                                            networkOptions: ClickstreamNetworkOptions())
    }

    override func tearDown() {
        persistence.deleteAll()
        warehouser = nil
        batchProcessor = nil
        batchSizeRegulator = nil
        appStateNotifier = nil
        schedulerService = nil
        batchCreator = nil
        networkBuilder = nil
        classifier = nil
        persistence = nil
        database = nil
        queue = nil
        super.tearDown()
    }

    private func makeProcessor(networkOptions: ClickstreamNetworkOptions = ClickstreamNetworkOptions(),
                               expiryManager: EventExpirationProtocol = FallbackEventExpirationManager()) -> CourierEventProcessor {
        CourierEventProcessor(performOnQueue: queue,
                              classifier: classifier,
                              eventWarehouser: warehouser,
                              sampler: nil,
                              networkOptions: networkOptions,
                              eventExpiryManager: expiryManager)
    }

    private func event(name: String = "test.event.Name",
                       cs: String? = nil,
                       guid: String = UUID().uuidString) -> ClickstreamEvent {
        ClickstreamEvent(guid: guid,
                         timeStamp: Date(),
                         message: nil,
                         eventName: name,
                         eventData: Data(),
                         csEventName: cs,
                         product: "CSTestProduct")
    }

    // MARK: - shouldTrackEvent

    func testShouldTrackEvent_whenMessageNameWhitelisted_returnsTrue() {
        let networkOptions = ClickstreamNetworkOptions(courierEventTypes: [""])
        let sut = makeProcessor(networkOptions: networkOptions)
        // ClickstreamEvent.messageName returns "" when message is nil.
        XCTAssertTrue(sut.shouldTrackEvent(event: event()))
    }

    func testShouldTrackEvent_whenMessageNameNotWhitelisted_returnsFalse() {
        let networkOptions = ClickstreamNetworkOptions(courierEventTypes: ["unknown.type"])
        let sut = makeProcessor(networkOptions: networkOptions)
        XCTAssertFalse(sut.shouldTrackEvent(event: event()))
    }

    // MARK: - sampleEvent

    func testSampleEvent_whenNoSamplerInjected_returnsTrue() {
        let sut = makeProcessor()
        XCTAssertTrue(sut.sampleEvent(event: event()))
    }

    // MARK: - createEvent

    func testCreateEvent_whenClassifierReturnsNil_doesNotPersist() {
        classifier.classificationResult = nil
        // Force the event onto the courier pipeline by enabling courier and disabling websocket.
        let networkOptions = ClickstreamNetworkOptions(isWebsocketEnabled: false,
                                                       isCourierEnabled: true,
                                                       isCourierPreAuthEnabled: true)
        let sut = makeProcessor(networkOptions: networkOptions)

        sut.createEvent(event: event(), isUserAuthenticated: true)

        let exp = expectation(description: "wait for queue to drain")
        queue.async {
            XCTAssertEqual(self.persistence.fetchAll()?.count ?? -1, 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    func testCreateEvent_whenShouldNotTrackOnCourier_doesNotPersist() {
        // Courier disabled -> shouldTrackOnCourier returns false.
        let networkOptions = ClickstreamNetworkOptions(isCourierEnabled: false)
        let sut = makeProcessor(networkOptions: networkOptions)

        sut.createEvent(event: event(), isUserAuthenticated: true)

        let exp = expectation(description: "wait for queue")
        queue.async {
            XCTAssertEqual(self.persistence.fetchAll()?.count ?? -1, 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    func testCreateEvent_whenAllChecksPass_persistsCourierEventWithExpectedTTL() {
        let networkOptions = ClickstreamNetworkOptions(isWebsocketEnabled: false,
                                                       isCourierEnabled: true,
                                                       isCourierPreAuthEnabled: true)
        let expiryManager = FallbackEventExpirationManager()
        let sut = makeProcessor(networkOptions: networkOptions, expiryManager: expiryManager)

        sut.createEvent(event: event(guid: "persisted-1"), isUserAuthenticated: true)

        let exp = expectation(description: "wait for queue")
        queue.asyncAfter(deadline: .now() + 0.3) {
            let all = self.persistence.fetchAll() ?? []
            XCTAssertEqual(all.count, 1)
            XCTAssertEqual(all.first?.guid, "persisted-1")
            // TTL should be roughly 6 fixed-30-day-months in the future.
            let expectedSeconds: TimeInterval = 6 * 30 * 24 * 60 * 60
            let actualSeconds = all.first?.ttl.timeIntervalSinceNow ?? 0
            XCTAssertEqual(actualSeconds, expectedSeconds, accuracy: 3)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }
}
