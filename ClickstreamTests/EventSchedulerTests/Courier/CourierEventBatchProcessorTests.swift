import Foundation
import XCTest
@testable import Clickstream

final class CourierEventBatchProcessorTests: XCTestCase {
    
    private var mockNetworkBuilder: MockNetworkBuilder!
    private var mockEventBatchCreator: CourierEventBatchCreator!
    private var mockSchedulerService: MockSchedulerService!
    private var mockAppStateNotifier: MockAppStateNotifierService!
    private var mockBatchSizeRegulator: CourierBatchSizeRegulator!
    private var mockPersistence: DefaultDatabaseDAO<CourierEvent>!
    private var sut: CourierEventBatchProcessor!
    
    private let database = try! DefaultDatabase(qos: .WAL)
    private let daoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue,
                                       qos: .utility,
                                       attributes: .concurrent)
    
    override func setUp() {
        super.setUp()
        mockNetworkBuilder = MockNetworkBuilder()
        mockEventBatchCreator = CourierEventBatchCreator(with: mockNetworkBuilder, performOnQueue: daoQueue)
        mockSchedulerService = MockSchedulerService()
        mockAppStateNotifier = MockAppStateNotifierService()
        mockBatchSizeRegulator = CourierBatchSizeRegulator()
        mockPersistence = DefaultDatabaseDAO<CourierEvent>(database: database, performOnQueue: daoQueue)
        
        sut = CourierEventBatchProcessor(
            with: mockEventBatchCreator,
            schedulerService: mockSchedulerService,
            appStateNotifier: mockAppStateNotifier,
            batchSizeRegulator: mockBatchSizeRegulator,
            persistence: mockPersistence
        )
    }
    
    override func tearDown() {
        sut = nil
        mockPersistence = nil
        mockBatchSizeRegulator = nil
        mockAppStateNotifier = nil
        mockSchedulerService = nil
        mockEventBatchCreator = nil
        super.tearDown()
    }
    
    func testStart_shouldSubscribeToScheduleAndObserveAppState() {
        sut.start()
        
        XCTAssertEqual(mockSchedulerService.startCallCount, 1)
        XCTAssertEqual(mockAppStateNotifier.startCallCount, 1)
        XCTAssertNotNil(mockSchedulerService.subscriber)
    }
    
    func testSendInstantly_shouldForwardEventAndReturnResult() {
        mockNetworkBuilder.isAvailableValue = true

        let event = CourierEvent.mock()
        let result = sut.sendInstantly(event: event)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockNetworkBuilder.trackBatchCallCount, 1)
    }
    
    func testSendP0_whenNoEvents_shouldNotForward() {
        mockNetworkBuilder.isAvailableValue = true
        sut.sendP0(classificationType: "p0")
        
        XCTAssertEqual(mockNetworkBuilder.trackBatchCallCount, 0)
    }

    func testSchedulerSubscriber_whenCannotForward_shouldNotProcessEvents() {
        sut.start()
                
        XCTAssertEqual(mockNetworkBuilder.trackBatchCallCount, 0)
    }
    
    func testAppStateNotification_willResignActive_shouldStopTimer() {
        sut.start()
        mockAppStateNotifier.stateChangeHandler?(.willResignActive)
        
        XCTAssertEqual(mockSchedulerService.stopCallCount, 1)
    }
    
    func testAppStateNotification_didBecomeActive_shouldStartTimer() {
        sut.start()
        mockAppStateNotifier.stateChangeHandler?(.didBecomeActive)
        
        XCTAssertEqual(mockSchedulerService.startCallCount, 2)
    }
    
    func testStop_shouldStopAllServices() {
        sut.stop()
        
        XCTAssertEqual(mockSchedulerService.stopCallCount, 1)
        XCTAssertEqual(mockAppStateNotifier.stopCallCount, 1)
    }
}

// MARK: - Mock Classes

class MockSchedulerService: SchedulerService {
    var subscriber: ((Priority) -> Void)?
    var startCallCount = 0
    var stopCallCount = 0
    
    func start() {
        startCallCount += 1
    }
    
    func stop() {
        stopCallCount += 1
    }
}

class MockAppStateNotifierService: AppStateNotifierService {
    var stateChangeHandler: ((AppStateNotificationType) -> Void)?
    var startCallCount = 0
    var stopCallCount = 0
    
    func start(with onStateChange: @escaping (AppStateNotificationType) -> Void) {
        startCallCount += 1
        stateChangeHandler = onStateChange
    }
    
    func stop() {
        stopCallCount += 1
    }
}

class MockBatchSizeRegulator: BatchSizeRegulator {

    var regulatedNumberResult = 0
    var regulatedNumberCallCount = 0
    var observeCallCount = 0
    
    func regulatedNumberOfItemsPerBatch(expectedBatchSize: Double) -> Int {
        regulatedNumberCallCount += 1
        return regulatedNumberResult
    }
    
    func observe(_ event: Event) {
        observeCallCount += 1
    }
}
