//
//  ClickStreamTests.swift
//  ClickStreamTests
//
//  Created by Anirudh Vyas on 27/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import XCTest
import SwiftProtobuf

class ClickStreamTests: XCTestCase {

    func testInitialiseClickStream() {
        // when
        let accessToken = "dummy_token"
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let url = URL(string: "ws://mock.clickstream.com/events")!
        let networkConfigs = NetworkConfigurations(baseURL: url, headers: headers)
        let clickStream = try! ClickStream.initialise(networkConfiguration: networkConfigs, constraints: MockConstants.constraints, eventClassification: MockConstants.eventClassification)
        
        // then
        XCTAssertNotNil(clickStream)
    }
}
