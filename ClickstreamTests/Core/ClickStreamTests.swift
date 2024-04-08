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
        let dummyRequest = URLRequest(url: URL(string: "dummy_url")!)
        let clickStream = try! Clickstream.initialise(with: dummyRequest, configurations: MockConstants.constraints, eventClassification: MockConstants.eventClassification, appPrefix: "")
        
        // then
        XCTAssertNotNil(clickStream)
    }
}
