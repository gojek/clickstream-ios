//
//  CourierIdentifiersTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 15/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class CourierIdentifiersTests: XCTestCase {

    func testInitWithAllParameters() {
        let credentials = CourierIdentifiers(
            userIdentifier: "user123",
            deviceIdentifier: "device456",
            bundleIdentifier: "com.test.app",
            extraIdentifier: "extra789"
        )
        
        XCTAssertEqual(credentials.userIdentifier, "user123")
        XCTAssertEqual(credentials.deviceIdentifier, "device456")
        XCTAssertEqual(credentials.bundleIdentifier, "com.test.app")
        XCTAssertEqual(credentials.extraIdentifier, "extra789")
    }
    
    func testInitWithDefaultParameters() {
        let credentials = CourierIdentifiers(userIdentifier: "testUser")
        
        XCTAssertEqual(credentials.userIdentifier, "testUser")
        XCTAssertNotNil(credentials.deviceIdentifier)
        XCTAssertFalse(credentials.deviceIdentifier.isEmpty)
    }
    
    func testInitWithNilOptionalParameters() {
        let credentials = CourierIdentifiers(
            userIdentifier: "user456",
            deviceIdentifier: "device789",
            bundleIdentifier: nil,
            extraIdentifier: nil
        )
        
        XCTAssertEqual(credentials.userIdentifier, "user456")
        XCTAssertEqual(credentials.deviceIdentifier, "device789")
        XCTAssertNil(credentials.bundleIdentifier)
        XCTAssertNil(credentials.extraIdentifier)
    }
    
    func testDeviceIdentifierGeneration() {
        let credentials1 = CourierIdentifiers(
            userIdentifier: "user1",
            deviceIdentifier: UUID().uuidString
        )
        let credentials2 = CourierIdentifiers(
            userIdentifier: "user2",
            deviceIdentifier: UUID().uuidString
        )
        
        XCTAssertNotEqual(credentials1.deviceIdentifier, credentials2.deviceIdentifier)
        XCTAssertTrue(credentials1.deviceIdentifier.count > 0)
        XCTAssertTrue(credentials2.deviceIdentifier.count > 0)
    }
    
    func testDeviceIdentifierFallbackGeneration() {
        let credentials = CourierIdentifiers(userIdentifier: "testUser")
        
        XCTAssertFalse(credentials.deviceIdentifier.isEmpty)
        XCTAssertTrue(credentials.deviceIdentifier.count >= 36)
    }
    
    func testUserIdentifierValidation() {
        let emptyUserCredentials = CourierIdentifiers(userIdentifier: "")
        let validUserCredentials = CourierIdentifiers(userIdentifier: "validUser")
        
        XCTAssertEqual(emptyUserCredentials.userIdentifier, "")
        XCTAssertEqual(validUserCredentials.userIdentifier, "validUser")
    }
}
