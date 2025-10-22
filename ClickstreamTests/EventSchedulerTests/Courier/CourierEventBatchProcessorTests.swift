import Foundation
import XCTest
@testable import Clickstream

final class CourierEventBatchProcessorTests: XCTestCase {
    
    private var mockEventBatchCreator: MockEventBatchCreator!
    private var mockSchedulerService: MockSchedulerService!
    private var mockAppStateNotifier: MockAppStateNotifierService!
    private var mockBatchSizeRegulator: MockBatchSizeRegulator!
    private var mockPersistence: DefaultDatabaseDAO<Event>!
    private var sut: CourierEventBatchProcessor!
    
    private let database = try! DefaultDatabase(qos: .WAL)
    private let daoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue,
                                       qos: .utility,
                                       attributes: .concurrent)
    
    override func setUp() {
        super.setUp()
        mockEventBatchCreator = MockEventBatchCreator()
        mockSchedulerService = MockSchedulerService()
        mockAppStateNotifier = MockAppStateNotifierService()
        mockBatchSizeRegulator = MockBatchSizeRegulator()
        mockPersistence = DefaultDatabaseDAO<Event>(database: database,
                                                    performOnQueue: daoQueue)
        
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
        mockEventBatchCreator.forwardResult = true
        let event = Event.mock()
        
        let result = sut.sendInstantly(event: event)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockEventBatchCreator.forwardCallCount, 1)
        XCTAssertEqual(mockEventBatchCreator.lastForwardedEvents?.count, 1)
    }
    
    func testSendP0_whenNoEvents_shouldNotForward() {
        sut.sendP0(classificationType: "p0")
        
        XCTAssertEqual(mockEventBatchCreator.forwardCallCount, 0)
    }

    func testSchedulerSubscriber_whenCannotForward_shouldNotProcessEvents() {
        mockEventBatchCreator.canForwardValue = false
        
        sut.start()
                
        XCTAssertEqual(mockEventBatchCreator.forwardCallCount, 0)
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
        XCTAssertEqual(mockEventBatchCreator.stopCallCount, 1)
    }
}

// MARK: - Mock Classes
private class MockEventBatchCreator: EventBatchCreator {
    var canForwardValue = false
    var forwardResult = false
    var forwardCallCount = 0
    var stopCallCount = 0
    var requestForConnectionCallCount = 0
    var lastForwardedEvents: [Event]?
    
    var canForward: Bool {
        return canForwardValue
    }
    
    func forward(with events: [Event]) -> Bool {
        forwardCallCount += 1
        lastForwardedEvents = events
        return forwardResult
    }
    
    func requestForConnection() {
        requestForConnectionCallCount += 1
    }
    
    func stop() {
        stopCallCount += 1
    }
}

private class MockSchedulerService: SchedulerService {
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

private class MockAppStateNotifierService: AppStateNotifierService {
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
