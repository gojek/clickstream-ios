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
    
    func testInitialiseClickstreamWithNetworkOptionsWebsocket() {
        // when
        let dummyRequest = URLRequest(url: URL(string: "dummy_url")!)
        let networkOptions = ClickstreamNetworkOptions(isEnabled: true, options: [.websocket])
        let clickStream = try! Clickstream.initialise(with: dummyRequest,
                                                      configurations: MockConstants.constraints,
                                                      eventClassification: MockConstants.eventClassification,
                                                      appPrefix: "",
                                                      networkOptions: networkOptions)
        
        // then
        XCTAssertNotNil(clickStream)
    }

    func testInitialiseClickstreamWithNetworkOptionsCourier() {
        // when
        let dummyRequest = URLRequest(url: URL(string: "dummy_url")!)
        let whitelistedEvents: Set<ClickstreamCourierEventIdentifier> = ["CSCourierEvent1", "CSCourierEvent2", "CSCourierEvent3"]
        let networkOptions = ClickstreamNetworkOptions(isEnabled: true, options: [.courier(events: whitelistedEvents)])
        let clickStream = try! Clickstream.initialise(with: dummyRequest,
                                                      configurations: MockConstants.constraints,
                                                      eventClassification: MockConstants.eventClassification,
                                                      appPrefix: "",
                                                      networkOptions: networkOptions)
        
        // then
        XCTAssertNotNil(clickStream)
    }
}
