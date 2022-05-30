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

    func testEventIntialization() {
        // given
        let timestamp = Date()
        let type = "ClickstreamTestRealtime"
        let eventProtoData = Data()
        
        // when
        let event = Event(guid: "", timestamp: timestamp, type: type, eventProtoData: eventProtoData)
        
        // then
        XCTAssertEqual(event.timestamp, timestamp)
        XCTAssertEqual(event.type, type)
        XCTAssertEqual(event.eventProtoData, eventProtoData)
    }
    
    func test_eventComparision_basedOnTimestamp() {
        // given
        let firstEvent = Event(guid: "", timestamp: Date(), type: "ClickstreamTestRealtime", eventProtoData: Data())
        let secondEvent = Event(guid: "", timestamp: Date.init(timeInterval: 1, since: Date()), type: "ClickstreamTestRealtime", eventProtoData: Data())
        
        // then
        XCTAssertTrue(firstEvent < secondEvent)
    }
}
