@testable import Clickstream
import XCTest
import SwiftProtobuf

class CourierEventBatchTests: XCTestCase {
    
    func testInit() {
        let uuid = UUID().uuidString
        let event = CourierEvent(guid: UUID().uuidString, timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: Data())
        
        let eventBatch = CourierEventBatch(uuid: uuid, events: [event])
        
        XCTAssertEqual(uuid, eventBatch.uuid)
        XCTAssertEqual([event], eventBatch.events)
    }
    
    func testInit_with_no_events() {
        let uuid = UUID().uuidString
        
        let eventBatch = CourierEventBatch(uuid: uuid)
        
        XCTAssertEqual(uuid, eventBatch.uuid)
        XCTAssertTrue(eventBatch.events.isEmpty)
    }
    
    func testInitWithEmptyUUID() {
        let event = CourierEvent(guid: UUID().uuidString, timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: Data())
        
        let eventBatch = CourierEventBatch(uuid: "", events: [event])
        
        XCTAssertTrue(eventBatch.uuid.isEmpty)
        XCTAssertEqual([event], eventBatch.events)
    }
    
    func testInitWithMultipleEvents() {
        let uuid = UUID().uuidString
        let event1 = CourierEvent(guid: "guid1", timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: Data())
        let event2 = CourierEvent(guid: "guid2", timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: Data())
        let events = [event1, event2]
        
        let eventBatch = CourierEventBatch(uuid: uuid, events: events)
        
        XCTAssertEqual(uuid, eventBatch.uuid)
        XCTAssertEqual(events, eventBatch.events)
        XCTAssertEqual(2, eventBatch.events.count)
    }
    
    func testEventBatchCodable() throws {
        let uuid = UUID().uuidString
        let event = CourierEvent(guid: UUID().uuidString, timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: "test".data(using: .utf8)!)
        let eventBatch = CourierEventBatch(uuid: uuid, events: [event])
        
        let encoded = try JSONEncoder().encode(eventBatch)
        let decoded = try JSONDecoder().decode(EventBatch.self, from: encoded)
        
        XCTAssertEqual(eventBatch.uuid, decoded.uuid)
        XCTAssertEqual(eventBatch.events.count, decoded.events.count)
        XCTAssertEqual(eventBatch.events.first?.guid, decoded.events.first?.guid)
    }
    
    func testEventBatchMutability() {
        var eventBatch = CourierEventBatch(uuid: UUID().uuidString)
        let event = CourierEvent(guid: UUID().uuidString, timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: Data())
        
        XCTAssertTrue(eventBatch.events.isEmpty)
        
        eventBatch.events.append(event)
        
        XCTAssertEqual(1, eventBatch.events.count)
        XCTAssertEqual(event, eventBatch.events.first)
    }
    
    func testEventBatchUUIDMutability() {
        var eventBatch = CourierEventBatch(uuid: "original-uuid")
        let newUUID = UUID().uuidString
        
        XCTAssertEqual("original-uuid", eventBatch.uuid)
        
        eventBatch.uuid = newUUID
        
        XCTAssertEqual(newUUID, eventBatch.uuid)
    }
}
