//
//  EventSpecificDataTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 26/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import XCTest

class EventSpecificDataTests: XCTestCase {

    func testInit() {
        // given
        let eventSpecificData = EventSpecificData()
        
        // then
        XCTAssertNotNil(eventSpecificData.uuid)
        XCTAssertNotNil(eventSpecificData.timeStamp)
    }
}
