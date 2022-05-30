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
        let accessToken = "dummy_token"
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let url = URL(string: "ws://mock.clickstream.com/events")!
        let networkConfigs = NetworkConfigurations(baseURL: url, headers: headers)
        let clickStream = try! Clickstream.initialise(networkConfiguration: networkConfigs, constraints: MockConstants.constraints, eventClassification: MockConstants.eventClassification)
        
        // then
        XCTAssertNotNil(clickStream)
    }
}
