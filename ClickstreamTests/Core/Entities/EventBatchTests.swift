//
//  EventBatchTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 26/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import SwiftProtobuf

class EventBatchTests: XCTestCase {
    
    func testInit() {
        let uuid = UUID().uuidString
        let event = Event(guid: UUID().uuidString, timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: Data())
        
        let eventBatch = EventBatch(uuid: uuid, events: [event])
        
        XCTAssertEqual(uuid, eventBatch.uuid)
        XCTAssertEqual([event], eventBatch.events)
    }
    
    func testInit_with_no_events() {
        let uuid = UUID().uuidString
        
        let eventBatch = EventBatch(uuid: uuid)
        
        XCTAssertEqual(uuid, eventBatch.uuid)
        XCTAssertTrue(eventBatch.events.isEmpty)
    }
    
    func testInitWithEmptyUUID() {
        let event = Event(guid: UUID().uuidString, timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: Data())
        
        let eventBatch = EventBatch(uuid: "", events: [event])
        
        XCTAssertTrue(eventBatch.uuid.isEmpty)
        XCTAssertEqual([event], eventBatch.events)
    }
    
    func testInitWithMultipleEvents() {
        let uuid = UUID().uuidString
        let event1 = Event(guid: "guid1", timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: Data())
        let event2 = Event(guid: "guid2", timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: Data())
        let events = [event1, event2]
        
        let eventBatch = EventBatch(uuid: uuid, events: events)
        
        XCTAssertEqual(uuid, eventBatch.uuid)
        XCTAssertEqual(events, eventBatch.events)
        XCTAssertEqual(2, eventBatch.events.count)
    }
    
    func testEventBatchCodable() throws {
        let uuid = UUID().uuidString
        let event = Event(guid: UUID().uuidString, timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: "test".data(using: .utf8)!)
        let eventBatch = EventBatch(uuid: uuid, events: [event])
        
        let encoded = try JSONEncoder().encode(eventBatch)
        let decoded = try JSONDecoder().decode(EventBatch.self, from: encoded)
        
        XCTAssertEqual(eventBatch.uuid, decoded.uuid)
        XCTAssertEqual(eventBatch.events.count, decoded.events.count)
        XCTAssertEqual(eventBatch.events.first?.guid, decoded.events.first?.guid)
    }
    
    func testEventBatchMutability() {
        var eventBatch = EventBatch(uuid: UUID().uuidString)
        let event = Event(guid: UUID().uuidString, timestamp: Date(), type: "realtime", isMirrored: false, eventProtoData: Data())
        
        XCTAssertTrue(eventBatch.events.isEmpty)
        
        eventBatch.events.append(event)
        
        XCTAssertEqual(1, eventBatch.events.count)
        XCTAssertEqual(event, eventBatch.events.first)
    }
    
    func testEventBatchUUIDMutability() {
        var eventBatch = EventBatch(uuid: "original-uuid")
        let newUUID = UUID().uuidString
        
        XCTAssertEqual("original-uuid", eventBatch.uuid)
        
        eventBatch.uuid = newUUID
        
        XCTAssertEqual(newUUID, eventBatch.uuid)
    }
}
