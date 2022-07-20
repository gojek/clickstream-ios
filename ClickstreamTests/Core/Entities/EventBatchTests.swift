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
        // given
        let uuid = UUID().uuidString
        let event = Event(guid: "", timestamp: Date(), type: "ClickstreamTestRealtime", eventProtoData: Data())
        
        // when
        let eventBatch = EventBatch(uuid: uuid, events: [event])
        
        // then
        XCTAssertEqual(uuid, eventBatch.uuid)
        XCTAssertEqual([event], eventBatch.events)
    }
    
    func testInit_with_no_events() {
        // given
        let uuid = UUID().uuidString
        
        // when
        let eventBatch = EventBatch(uuid: uuid)
        
        // then
        XCTAssertTrue(eventBatch.events.isEmpty)
    }
}
