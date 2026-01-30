import XCTest
import GRDB
@testable import Clickstream

final class CourierEventTests: XCTestCase {
    
    func testEventInitialization() {
        let guid = UUID().uuidString
        let timestamp = Date()
        let type = "realtime"
        let eventProtoData = "test data".data(using: .utf8)!
        
        let event = CourierEvent(guid: guid, timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        
        XCTAssertEqual(event.guid, guid)
        XCTAssertEqual(event.timestamp, timestamp)
        XCTAssertEqual(event.type, type)
        XCTAssertEqual(event.eventProtoData, eventProtoData)
    }
    
    func testEventInitializationWithEmptyData() {
        let guid = ""
        let timestamp = Date()
        let type = "realtime"
        let eventProtoData = Data()
        
        let event = CourierEvent(guid: guid, timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        
        XCTAssertEqual(event.guid, guid)
        XCTAssertEqual(event.timestamp, timestamp)
        XCTAssertEqual(event.type, type)
        XCTAssertTrue(event.eventProtoData.isEmpty)
    }
    
    func testEventComparison_basedOnTimestamp() {
        let baseDate = Date()
        let firstEvent = CourierEvent(guid: "1", timestamp: baseDate, type: "realtime", isMirrored: false, eventProtoData: Data())
        let secondEvent = CourierEvent(guid: "2", timestamp: Date(timeInterval: 1, since: baseDate), type: "realtime", isMirrored: false, eventProtoData: Data())
        
        XCTAssertTrue(firstEvent < secondEvent)
        XCTAssertFalse(secondEvent < firstEvent)
    }
    
    func testEventComparison_equalTimestamps() {
        let timestamp = Date()
        let firstEvent = CourierEvent(guid: "1", timestamp: timestamp, type: "realtime", isMirrored: false, eventProtoData: Data())
        let secondEvent = CourierEvent(guid: "2", timestamp: timestamp, type: "realtime", isMirrored: false, eventProtoData: Data())
        
        XCTAssertFalse(firstEvent < secondEvent)
        XCTAssertFalse(secondEvent < firstEvent)
    }
    
    func testEventEquality() {
        let guid = "test-guid"
        let timestamp = Date()
        let type = "realtime"
        let eventProtoData = Data()
        
        let event1 = CourierEvent(guid: guid, timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        let event2 = CourierEvent(guid: guid, timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        
        XCTAssertEqual(event1, event2)
    }
    
    func testEventInequality_differentGuid() {
        let timestamp = Date()
        let type = "realtime"
        let eventProtoData = Data()
        
        let event1 = CourierEvent(guid: "guid1", timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        let event2 = CourierEvent(guid: "guid2", timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        
        XCTAssertNotEqual(event1, event2)
    }
    
    func testEventCodable() throws {
        let event = CourierEvent(
            guid: UUID().uuidString,
            timestamp: Date(),
            type: "realtime",
            isMirrored: false,
            eventProtoData: "test".data(using: .utf8)!
        )
        
        let encoded = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(Event.self, from: encoded)
        
        XCTAssertEqual(event.guid, decoded.guid)
        XCTAssertEqual(event.type, decoded.type)
        XCTAssertEqual(event.eventProtoData, decoded.eventProtoData)
    }
    
    func testEventTableName() {
        XCTAssertEqual(CourierEvent.tableName, "courierEvent")
    }
    
    func testEventTableMigrations() {
        XCTAssertNil(CourierEvent.tableMigrations)
    }
    
    func testEventColumns() {
        XCTAssertEqual(CourierEvent.Columns.type.name, "type")
    }
}
