//
//  ClickstreamTests.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 27/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import SwiftProtobuf

class ClickstreamTests: XCTestCase {

    func testInitialiseClickstream() {
        // when
        let dummyRequest = URLRequest(url: URL(string: "ws://mock.clickstream.com/events")!)
        let clickStream = try! Clickstream.initialise(request: dummyRequest, constraints: MockConstants.constraints, eventClassification: MockConstants.eventClassification, dataSource: self)
        
        // then
        XCTAssertNotNil(clickStream)
    }
}

extension ClickstreamTests: ClickstreamDataSource {
    
    func currentNTPTimestamp() -> Date? {
        return Date()
    }
}
