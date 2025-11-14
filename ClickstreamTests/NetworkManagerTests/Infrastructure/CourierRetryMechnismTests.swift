////
////  CourierRetryMechanismTests.swift
////  ClickstreamTests
////
////  Created by Luqman Fauzi on 06/10/25.
////  Copyright © 2025 Gojek. All rights reserved.
////
//
//@testable import Clickstream
//import XCTest
//import CourierCore
//
//class CourierRetryMechanismTests: XCTestCase {
//    
//    private var sut: CourierRetryMechanism!
//    private var mockNetworkOptions: MockClickstreamNetworkOptions!
//    private var mockNetworkService: MockCourierNetworkService!
//    private var mockReachability: MockNetworkReachability!
//    private var mockDeviceStatus: MockDeviceStatus!
//    private var mockAppStateNotifier: MockAppStateNotifier!
//    private var mockQueue: MockSerialQueue!
//    private var mockPersistence: MockDatabaseDAO!
//    private var database: DefaultDatabase!
//    
//    override func setUp() {
//        super.setUp()
//        
//        database = try! DefaultDatabase(qos: .utility)
//        mockNetworkOptions = MockClickstreamNetworkOptions()
//        mockNetworkService = MockCourierNetworkService()
//        mockReachability = MockNetworkReachability()
//        mockDeviceStatus = MockDeviceStatus()
//        mockAppStateNotifier = MockAppStateNotifier()
//        mockQueue = MockSerialQueue()
//        mockPersistence = MockDatabaseDAO(database: database)
//        
//        setupDefaultMockBehavior()
//        
//        sut = CourierRetryMechanism(
//            networkOptions: mockNetworkOptions,
//            networkService: mockNetworkService,
//            reachability: mockReachability,
//            deviceStatus: mockDeviceStatus,
//            appStateNotifier: mockAppStateNotifier,
//            performOnQueue: mockQueue,
//            persistence: mockPersistence
//        )
//    }
//    
//    override func tearDown() {
//        sut = nil
//        mockNetworkOptions = nil
//        mockNetworkService = nil
//        mockReachability = nil
//        mockDeviceStatus = nil
//        mockAppStateNotifier = nil
//        mockQueue = nil
//        mockPersistence = nil
//        database = nil
//        super.tearDown()
//    }
//    
//    private func setupDefaultMockBehavior() {
//        mockReachability.isAvailable = true
//        mockNetworkService.isConnected = true
//        mockDeviceStatus.isDeviceLowOnPower = false
//        mockNetworkOptions.isCourierEnabled = true
//    }
//    
//    func test_initialization_setsUpObservers() {
//        XCTAssertTrue(mockAppStateNotifier.startCalled)
//        XCTAssertTrue(mockDeviceStatus.startTrackingCalled)
//        XCTAssertTrue(mockReachability.startNotifierCalled)
//    }
//    
//    func test_isAvailable_whenAllConditionsAreTrue_returnsTrue() {
//        mockReachability.isAvailable = true
//        mockNetworkService.isConnected = true
//        mockDeviceStatus.isDeviceLowOnPower = false
//        
//        XCTAssertTrue(sut.isAvailble)
//    }
//    
//    func test_isAvailable_whenNetworkNotReachable_returnsFalse() {
//        mockReachability.isAvailable = false
//        mockNetworkService.isConnected = true
//        mockDeviceStatus.isDeviceLowOnPower = false
//        
//        XCTAssertFalse(sut.isAvailble)
//    }
//    
//    func test_isAvailable_whenNotConnected_returnsFalse() {
//        mockReachability.isAvailable = true
//        mockNetworkService.isConnected = false
//        mockDeviceStatus.isDeviceLowOnPower = false
//        
//        XCTAssertFalse(sut.isAvailble)
//    }
//    
//    func test_isAvailable_whenDeviceLowOnPower_returnsFalse() {
//        mockReachability.isAvailable = true
//        mockNetworkService.isConnected = true
//        mockDeviceStatus.isDeviceLowOnPower = true
//        
//        XCTAssertFalse(sut.isAvailble)
//    }
//    
//    func test_trackBatch_whenTopicIsNil_returnsEarly() {
//        let eventRequest = CourierEventRequest(guid: UUID().uuidString)
//        
//        sut.trackBatch(with: eventRequest)
//        
//        XCTAssertFalse(mockNetworkService.publishCalled)
//    }
//    
//    func test_trackBatch_whenEventTypeIsNotInstant_addsToCache() {
//        configureIdentifiersAndTopic()
//        let eventRequest = CourierEventRequest(guid: UUID().uuidString)
//        eventRequest.eventType = .realTime
//        
//        sut.trackBatch(with: eventRequest)
//        
//        XCTAssertTrue(mockPersistence.insertCalled)
//    }
//    
//    func test_trackBatch_whenEventTypeIsInstant_doesNotAddToCache() {
//        configureIdentifiersAndTopic()
//        let eventRequest = CourierEventRequest(guid: UUID().uuidString)
//        eventRequest.eventType = .instant
//        
//        sut.trackBatch(with: eventRequest)
//        
//        XCTAssertFalse(mockPersistence.insertCalled)
//    }
//    
//    func test_trackBatch_whenPublishSucceeds_removesFromCache() {
//        configureIdentifiersAndTopic()
//        mockNetworkService.publishShouldSucceed = true
//        let eventRequest = CourierEventRequest(guid: UUID().uuidString)
//        
//        sut.trackBatch(with: eventRequest)
//        
//        let expectation = XCTestExpectation(description: "Async publish completes")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            XCTAssertTrue(self.mockPersistence.deleteOneCalled)
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: 1.0)
//    }
//    
//    func test_configureIdentifiers_setsIdentifiersAndTopic() {
//        let identifiers = CourierIdentifiers(clientId: "test", username: "user", password: "pass")
//        let topic = "test-topic"
//        
//        sut.configureIdentifiers(with: identifiers, topic: topic)
//        
//        XCTAssertTrue(mockNetworkService.initiateSecondaryConnectionCalled)
//    }
//    
//    func test_removeIdentifiers_clearsIdentifiersAndStopsTracking() {
//        configureIdentifiersAndTopic()
//        
//        sut.removeIdentifiers()
//        
//        XCTAssertTrue(mockAppStateNotifier.stopCalled)
//        XCTAssertTrue(mockDeviceStatus.stopTrackingCalled)
//        XCTAssertTrue(mockReachability.stopNotifierCalled)
//    }
//    
//    func test_openConnectionForcefully_callsEstablishConnectionWithKeepTrying() {
//        configureIdentifiersAndTopic()
//        
//        sut.openConnectionForcefully()
//        
//        XCTAssertTrue(mockNetworkService.initiateSecondaryConnectionCalled)
//        XCTAssertTrue(mockNetworkService.lastKeepTryingValue)
//    }
//    
//    func test_stopTracking_stopsAllServices() {
//        sut.stopTracking()
//        
//        XCTAssertTrue(mockAppStateNotifier.stopCalled)
//        XCTAssertTrue(mockDeviceStatus.stopTrackingCalled)
//        XCTAssertTrue(mockReachability.stopNotifierCalled)
//        XCTAssertTrue(mockNetworkService.terminateConnectionCalled)
//    }
//    
//    func test_appStateWillResignActive_preparesForTermination() {
//        mockAppStateNotifier.triggerStateChange(.willResignActive)
//        
//        XCTAssertTrue(mockQueue.asyncAfterCalled)
//    }
//    
//    func test_appStateDidBecomeActive_establishesConnection() {
//        configureIdentifiersAndTopic()
//        
//        mockAppStateNotifier.triggerStateChange(.didBecomeActive)
//        
//        XCTAssertTrue(mockNetworkService.initiateSecondaryConnectionCalled)
//    }
//    
//    func test_networkReachable_establishesConnection() {
//        configureIdentifiersAndTopic()
//        
//        mockReachability.triggerReachable()
//        
//        XCTAssertTrue(mockNetworkService.initiateSecondaryConnectionCalled)
//    }
//    
//    func test_networkUnreachable_terminatesConnection() {
//        mockReachability.triggerUnreachable()
//        
//        XCTAssertTrue(mockNetworkService.terminateConnectionCalled)
//    }
//    
//    func test_batteryStatusChanged_whenLowPowerAndConnected_terminatesConnection() {
//        mockNetworkService.isConnected = true
//        
//        mockDeviceStatus.triggerBatteryStatusChanged(isLowOnPower: true)
//        
//        XCTAssertTrue(mockNetworkService.terminateConnectionCalled)
//    }
//    
//    func test_batteryStatusChanged_whenNotLowPowerAndNotConnected_establishesConnection() {
//        configureIdentifiersAndTopic()
//        mockNetworkService.isConnected = false
//        
//        mockDeviceStatus.triggerBatteryStatusChanged(isLowOnPower: false)
//        
//        XCTAssertTrue(mockNetworkService.initiateSecondaryConnectionCalled)
//    }
//    
//    func test_addToCache_whenEventRequestNotExists_insertsEventRequest() {
//        let eventRequest = CourierEventRequest(guid: UUID().uuidString)
//        mockPersistence.fetchOneResult = nil
//        
//        sut.trackBatch(with: eventRequest)
//        
//        XCTAssertTrue(mockPersistence.insertCalled)
//    }
//    
//    func test_addToCache_whenEventRequestExistsAndRetriesNotExhausted_updatesEventRequest() {
//        let eventRequest = CourierEventRequest(guid: UUID().uuidString)
//        var existingRequest = CourierEventRequest(guid: eventRequest.guid)
//        existingRequest.retriesMade = 1
//        mockPersistence.fetchOneResult = existingRequest
//        
//        Clickstream.configurations = ClickstreamConstraints(maxRetriesPerBatch: 3)
//        
//        sut.trackBatch(with: eventRequest)
//        
//        XCTAssertTrue(mockPersistence.updateCalled)
//    }
//    
//    func test_addToCache_whenEventRequestExistsAndRetriesExhausted_deletesEventRequest() {
//        let eventRequest = CourierEventRequest(guid: UUID().uuidString)
//        var existingRequest = CourierEventRequest(guid: eventRequest.guid)
//        existingRequest.retriesMade = 5
//        mockPersistence.fetchOneResult = existingRequest
//        
//        Clickstream.configurations = ClickstreamConstraints(maxRetriesPerBatch: 3)
//        
//        sut.trackBatch(with: eventRequest)
//        
//        XCTAssertTrue(mockPersistence.deleteOneCalled)
//    }
//    
//    func test_retryFailedBatch_whenCourierRetryEnabled_tracksBatchViaCourier() {
//        configureIdentifiersAndTopic()
//        mockNetworkOptions.courierConfig.retryPolicy.isEnabled = true
//        mockNetworkOptions.courierConfig.retryPolicy.maxRetryCount = 3
//        
//        let eventRequest = CourierEventRequest(guid: UUID().uuidString)
//        eventRequest.retryCount = 1
//        
//        let expectation = XCTestExpectation(description: "Retry completes")
//        mockQueue.asyncAfterBlock = { [weak self] in
//            XCTAssertTrue(self?.mockNetworkService.publishCalled ?? false)
//            expectation.fulfill()
//        }
//        
//        triggerRetryFailedBatch(with: eventRequest)
//        
//        wait(for: [expectation], timeout: 1.0)
//    }
//    
//    func test_retryFailedBatch_whenHttpRetryEnabled_fallsBackToHTTP() {
//        configureIdentifiersAndTopic()
//        mockNetworkOptions.courierConfig.retryPolicy.isEnabled = false
//        mockNetworkOptions.courierConfig.httpRetryPolicy.isEnabled = true
//        mockNetworkOptions.courierConfig.httpRetryPolicy.maxRetryCount = 3
//        
//        let eventRequest = CourierEventRequest(guid: UUID().uuidString)
//        eventRequest.retryCount = 1
//        
//        let expectation = XCTestExpectation(description: "HTTP retry completes")
//        mockQueue.asyncAfterBlock = { [weak self] in
//            XCTAssertTrue(self?.mockNetworkService.executeHTTPRequestCalled ?? false)
//            expectation.fulfill()
//        }
//        
//        triggerRetryFailedBatch(with: eventRequest)
//        
//        wait(for: [expectation], timeout: 1.0)
//    }
//    
//    func test_onEvent_messageSendSuccess_returnsWithoutAction() {
//        let event = CourierEvent(type: .messageSendSuccess)
//        
//        sut.onEvent(event)
//        
//        XCTAssertFalse(mockNetworkService.publishCalled)
//        XCTAssertFalse(mockPersistence.updateCalled)
//    }
//    
//    func test_onEvent_messageSendFailure_returnsWithoutAction() {
//        let event = CourierEvent(type: .messageSendFailure(messageId: "test", topic: "topic", error: NSError(domain: "test", code: 1), qos: .atMostOnce))
//        
//        sut.onEvent(event)
//        
//        XCTAssertFalse(mockNetworkService.publishCalled)
//        XCTAssertFalse(mockPersistence.updateCalled)
//    }
//    
//    private func configureIdentifiersAndTopic() {
//        let identifiers = CourierIdentifiers(clientId: "test", username: "user", password: "pass")
//        sut.configureIdentifiers(with: identifiers, topic: "test-topic")
//    }
//    
//    private func triggerRetryFailedBatch(with eventRequest: CourierEventRequest) {
//        mockPersistence.fetchAllResult = [eventRequest]
//        mockReachability.isAvailable = true
//        mockNetworkService.isConnected = true
//        mockDeviceStatus.isDeviceLowOnPower = false
//        
//        let mirror = Mirror(reflecting: sut!)
//        if let retryMethod = mirror.children.first(where: { $0.label == "retryFailedBatch" }) {
//            sut.perform(Selector(("retryFailedBatch:")), with: eventRequest)
//        }
//    }
//}
//
//// MARK: - Mock Classes
//
//class MockClickstreamNetworkOptions: ClickstreamNetworkOptions {
//    var isCourierEnabled: Bool = true
//    var courierConfig = MockCourierConfig()
//}
//
//class MockCourierConfig {
//    var retryPolicy = MockRetryPolicy()
//    var httpRetryPolicy = MockRetryPolicy()
//}
//
//class MockRetryPolicy {
//    var isEnabled: Bool = false
//    var maxRetryCount: Int = 0
//}
//
//class MockCourierNetworkService<C: CourierConnectable>: NetworkService {
//
//    var isConnected: Bool = false
//    var publishCalled = false
//    var publishShouldSucceed = false
//    var executeHTTPRequestCalled = false
//    var terminateConnectionCalled = false
//    var initiateSecondaryConnectionCalled = false
//    var lastKeepTryingValue = false
//    
//    func publish(_ eventRequest: CourierEventRequest, topic: String) async throws {
//        publishCalled = true
//        if !publishShouldSucceed {
//            throw NSError(domain: "MockError", code: 1)
//        }
//    }
//    
//    func executeHTTPRequest(_ eventRequest: CourierEventRequest) async throws -> Odpf_Raccoon_EventResponse {
//        executeHTTPRequestCalled = true
//        return Odpf_Raccoon_EventResponse()
//    }
//    
//    func terminateConnection() {
//        terminateConnectionCalled = true
//    }
//    
//    func initiateSecondaryConnection(connectionStatusListener: @escaping (Result<ConnectableState, Error>) -> Void, keepTrying: Bool, identifiers: CourierIdentifiers, eventHandler: ICourierEventHandler?) async {
//        initiateSecondaryConnectionCalled = true
//        lastKeepTryingValue = keepTrying
//    }
//    
//    func flushConnectable() {
//        assertionFailure("Not to be called")
//    }
//}
//
//class MockNetworkReachability: NetworkReachability {
//
//    var connectionRetryCoefficient: TimeInterval = 0.0
//    
//    var isAvailable: Bool = true
//    var whenReachable: ((NetworkReachability) -> Void)?
//    var whenUnreachable: ((NetworkReachability) -> Void)?
//    var startNotifierCalled = false
//    var stopNotifierCalled = false
//    
//    func startNotifier() throws {
//        startNotifierCalled = true
//    }
//    
//    func stopNotifier() {
//        stopNotifierCalled = true
//    }
//    
//    func triggerReachable() {
//        whenReachable?(self)
//    }
//    
//    func triggerUnreachable() {
//        whenUnreachable?(self)
//    }
//
//    func getNetworkType() -> NetworkType {
//        return .wifi
//    }
//}
//
//class MockDeviceStatus: DefaultDeviceStatus {
//    var isDeviceLowOnPower: Bool = false
//    var onBatteryStatusChanged: ((Bool) -> Void)?
//    var startTrackingCalled = false
//    var stopTrackingCalled = false
//    
//    override func startTracking() {
//        startTrackingCalled = true
//    }
//    
//    override func stopTracking() {
//        stopTrackingCalled = true
//    }
//    
//    func triggerBatteryStatusChanged(isLowOnPower: Bool) {
//        onBatteryStatusChanged?(isLowOnPower)
//    }
//}
//
//class MockAppStateNotifier: AppStateNotifierService {
//    var startCalled = false
//    var stopCalled = false
//    var stateChangeBlock: ((AppStateChange) -> Void)?
//    
//    func start(stateChangeHandler: @escaping (AppStateChange) -> Void) {
//        startCalled = true
//        stateChangeBlock = stateChangeHandler
//    }
//    
//    func stop() {
//        stopCalled = true
//    }
//    
//    func triggerStateChange(_ state: AppStateChange) {
//        stateChangeBlock?(state)
//    }
//}
//
//class MockSerialQueue: SerialQueue {
//    var asyncAfterCalled = false
//    var asyncAfterBlock: (() -> Void)?
//    
//    override func asyncAfter(deadline: DispatchTime, execute work: @escaping () -> Void) {
//        asyncAfterCalled = true
//        asyncAfterBlock = work
//        work()
//    }
//}
//
//class MockDatabaseDAO: DefaultDatabaseDAO<CourierEventRequest> {
//    var insertCalled = false
//    var updateCalled = false
//    var deleteOneCalled = false
//    var fetchOneCalled = false
//    var fetchAllCalled = false
//    var fetchOneResult: CourierEventRequest?
//    var fetchAllResult: [CourierEventRequest]?
//    
//    override func insert(_ object: CourierEventRequest) {
//        insertCalled = true
//    }
//    
//    override func update(_ object: CourierEventRequest) {
//        updateCalled = true
//    }
//    
//    override func deleteOne(_ id: String) {
//        deleteOneCalled = true
//    }
//    
//    override func fetchOne(_ id: String) -> CourierEventRequest? {
//        fetchOneCalled = true
//        return fetchOneResult
//    }
//    
//    override func fetchAll() -> [CourierEventRequest]? {
//        fetchAllCalled = true
//        return fetchAllResult
//    }
//}
