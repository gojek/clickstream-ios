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
        let clickStream = try! Clickstream.initialise(with: dummyRequest, configurations: ClickstreamConstraints(), eventClassification: ClickstreamEventClassification(), dataSource: self, appPrefix: "")
        
        // then
        XCTAssertNotNil(clickStream)
    }
    
    func testDataSource() {
        // when
        let dummyRequest = URLRequest(url: URL(string: "dummy_url")!)
        let clickStream = try! Clickstream.initialise(with: dummyRequest, configurations: ClickstreamConstraints(), eventClassification: ClickstreamEventClassification(), dataSource: self, appPrefix: "")
        
        // then
        XCTAssertNotNil(clickStream?.dataSource)
    }
}

extension ClickstreamTests: ClickstreamDataSource {
    func currentUserLocation() -> CSLocation? {
        return CSLocation(longitude: 0.0, latitude: 0.0)
    }
    
    func currentNTPTimestamp() -> Date? {
        return Date()
    }
}
