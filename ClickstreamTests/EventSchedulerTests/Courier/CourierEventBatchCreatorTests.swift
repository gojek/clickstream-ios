import Foundation
import XCTest
@testable import Clickstream

final class CourierEventBatchCreatorTests: XCTestCase {
    
    private var schedulerQueue: DispatchQueue!
    private var mockNetworkBuilder: MockNetworkBuilder!
    private var sut: CourierEventBatchCreator!
    
    override func setUp() {
        super.setUp()
        mockNetworkBuilder = MockNetworkBuilder()
        schedulerQueue = SerialQueue(label: Constants.QueueIdentifiers.scheduler.rawValue, qos: .utility)
        sut = CourierEventBatchCreator(with: mockNetworkBuilder, performOnQueue: schedulerQueue)
    }
    
    override func tearDown() {
        sut = nil
        schedulerQueue = nil
        mockNetworkBuilder = nil
        super.tearDown()
    }
    
    func testForward_whenCanForward_shouldTrackBatchAndReturnTrue() {
        mockNetworkBuilder.isAvailableValue = true
        let events = [CourierEvent.mock(), CourierEvent.mock()]
        
        let result = sut.forward(with: events)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockNetworkBuilder.trackBatchCallCount, 1)
        XCTAssertEqual(mockNetworkBuilder.lastTrackedBatch?.events.count, 2)
    }
    
    func testForward_whenCannotForward_shouldReturnFalse() {
        mockNetworkBuilder.isAvailableValue = false
        let events = [CourierEvent.mock()]
        
        let result = sut.forward(with: events)
        
        XCTAssertFalse(result)
        XCTAssertEqual(mockNetworkBuilder.trackBatchCallCount, 0)
    }
    
    func testForward_shouldCreateBatchWithUniqueUUID() {
        mockNetworkBuilder.isAvailableValue = true
        let events = [CourierEvent.mock()]
        
        _ = sut.forward(with: events)
        
        XCTAssertNotNil(mockNetworkBuilder.lastTrackedBatch?.uuid)
        XCTAssertFalse(mockNetworkBuilder.lastTrackedBatch?.uuid.isEmpty ?? true)
    }
    
    func testRequestForConnection_shouldCallOpenConnectionForcefully() {
        sut.requestForConnection()
        
        XCTAssertEqual(mockNetworkBuilder.openConnectionForcefullyCallCount, 1)
    }
    
    func testStop_shouldCallStopTracking() {
        sut.stop()
        
        XCTAssertEqual(mockNetworkBuilder.stopTrackingCallCount, 1)
    }
    
    func testCanForward_shouldReturnNetworkBuilderAvailability() {
        mockNetworkBuilder.isAvailableValue = true
        XCTAssertTrue(sut.canForward)
        
        mockNetworkBuilder.isAvailableValue = false
        XCTAssertFalse(sut.canForward)
    }
}

// MARK: - Mock Classes
class MockNetworkBuilder: NetworkBuildable {
    typealias BatchType = CourierEventBatch
    
    var isAvailableValue = false
    var trackBatchCallCount = 0
    var openConnectionForcefullyCallCount = 0
    var stopTrackingCallCount = 0
    var lastTrackedBatch: CourierEventBatch?
    
    var isAvailable: Bool {
        return isAvailableValue
    }
    
    func trackBatch<T: EventBatchPersistable>(_ eventBatch: T, completion: ((_ error: Error?) -> Void)?) {
        trackBatchCallCount += 1
        lastTrackedBatch = eventBatch as? CourierEventBatch
    }
    
    func openConnectionForcefully() {
        openConnectionForcefullyCallCount += 1
    }
    
    func stopTracking() {
        stopTrackingCallCount += 1
    }
}

extension CourierEvent {
    static func mock(type: String = "test_event", guid: String = UUID().uuidString) -> Self {
        return CourierEvent(guid: guid, timestamp: Date(), type: type, eventProtoData: Data())
    }
}
