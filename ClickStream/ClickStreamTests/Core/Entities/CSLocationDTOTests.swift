//
//  CSLocationTests.swift
//  ClickStreamTests
//
//  Created by Abhijeet Mallick on 26/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import XCTest

class CSLocationTests: XCTestCase {

    func testInit() {
        // given
        let longitude = 100.0
        let latitude = 200.0
        
        // when
        let location = CSLocation.init(longitude: longitude, latitude: latitude)
        
        // then
        XCTAssertEqual(location.longitude, longitude)
        XCTAssertEqual(location.latitude, latitude)
    }
}
