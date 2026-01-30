//
//  EventTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 26/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class EventTests: XCTestCase {

    func testEventInitialization() {
        let guid = UUID().uuidString
        let timestamp = Date()
        let type = "realtime"
        let eventProtoData = "test data".data(using: .utf8)!
        
        let event = Event(guid: guid, timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        
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
        
        let event = Event(guid: guid, timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        
        XCTAssertEqual(event.guid, guid)
        XCTAssertEqual(event.timestamp, timestamp)
        XCTAssertEqual(event.type, type)
        XCTAssertTrue(event.eventProtoData.isEmpty)
    }
    
    func testEventComparison_basedOnTimestamp() {
        let baseDate = Date()
        let firstEvent = Event(guid: "1", timestamp: baseDate, type: "realtime", isMirrored: false, eventProtoData: Data())
        let secondEvent = Event(guid: "2", timestamp: Date(timeInterval: 1, since: baseDate), type: "realtime", isMirrored: false, eventProtoData: Data())
        
        XCTAssertTrue(firstEvent < secondEvent)
        XCTAssertFalse(secondEvent < firstEvent)
    }
    
    func testEventComparison_equalTimestamps() {
        let timestamp = Date()
        let firstEvent = Event(guid: "1", timestamp: timestamp, type: "realtime", isMirrored: false, eventProtoData: Data())
        let secondEvent = Event(guid: "2", timestamp: timestamp, type: "realtime", isMirrored: false, eventProtoData: Data())
        
        XCTAssertFalse(firstEvent < secondEvent)
        XCTAssertFalse(secondEvent < firstEvent)
    }
    
    func testEventEquality() {
        let guid = "test-guid"
        let timestamp = Date()
        let type = "realtime"
        let eventProtoData = Data()
        
        let event1 = Event(guid: guid, timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        let event2 = Event(guid: guid, timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        
        XCTAssertEqual(event1, event2)
    }
    
    func testEventInequality_differentGuid() {
        let timestamp = Date()
        let type = "realtime"
        let eventProtoData = Data()
        
        let event1 = Event(guid: "guid1", timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        let event2 = Event(guid: "guid2", timestamp: timestamp, type: type, isMirrored: false, eventProtoData: eventProtoData)
        
        XCTAssertNotEqual(event1, event2)
    }
    
    func testEventCodable() throws {
        let event = Event(
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
        XCTAssertEqual(Event.tableName, "event")
    }
    
    func testEventTableMigrations() {
        XCTAssertNil(Event.tableMigrations)
    }
    
    func testEventColumns() {
        XCTAssertEqual(Event.Columns.type.name, "type")
    }
}
