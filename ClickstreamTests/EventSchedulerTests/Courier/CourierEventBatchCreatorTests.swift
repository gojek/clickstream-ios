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
        let events = [Event.mock(), Event.mock()]
        
        let result = sut.forward(with: events)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockNetworkBuilder.trackBatchCallCount, 1)
        XCTAssertEqual(mockNetworkBuilder.lastTrackedBatch?.events.count, 2)
    }
    
    func testForward_whenCannotForward_shouldReturnFalse() {
        mockNetworkBuilder.isAvailableValue = false
        let events = [Event.mock()]
        
        let result = sut.forward(with: events)
        
        XCTAssertFalse(result)
        XCTAssertEqual(mockNetworkBuilder.trackBatchCallCount, 0)
    }
    
    func testForward_shouldCreateBatchWithUniqueUUID() {
        mockNetworkBuilder.isAvailableValue = true
        let events = [Event.mock()]
        
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
private class MockNetworkBuilder: NetworkBuildable {
    var isAvailableValue = false
    var trackBatchCallCount = 0
    var openConnectionForcefullyCallCount = 0
    var stopTrackingCallCount = 0
    var lastTrackedBatch: EventBatch?
    
    var isAvailable: Bool {
        return isAvailableValue
    }
    
    func trackBatch(_ batch: EventBatch, completion: ((Error?) -> ())?) {
        trackBatchCallCount += 1
        lastTrackedBatch = batch
    }
    
    func openConnectionForcefully() {
        openConnectionForcefullyCallCount += 1
    }
    
    func stopTracking() {
        stopTrackingCallCount += 1
    }
}

extension Event {
    static func mock(type: String = "test_event", guid: String = UUID().uuidString) -> Event {
        return Event(guid: guid, timestamp: Date(), type: type, eventProtoData: Data())
    }
}
