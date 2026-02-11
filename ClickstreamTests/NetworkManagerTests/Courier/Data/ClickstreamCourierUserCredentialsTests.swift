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
        let credentials = CourierPostAuthIdentifiers(
            userIdentifier: "user123",
            deviceIdentifier: "device456",
            bundleIdentifier: "com.test.app",
            ownerType: "clickstream",
        )
        
        XCTAssertEqual(credentials.userIdentifier, "user123")
        XCTAssertEqual(credentials.deviceIdentifier, "device456")
        XCTAssertEqual(credentials.bundleIdentifier, "com.test.app")
        XCTAssertEqual(credentials.ownerType, "clickstream")
    }
    
    func testInitWithDefaultParameters() {
        let credentials = CourierPostAuthIdentifiers(userIdentifier: "testUser", ownerType:  "clickstream")
        
        XCTAssertEqual(credentials.userIdentifier, "testUser")
        XCTAssertEqual(credentials.ownerType, "clickstream")
        XCTAssertNotNil(credentials.deviceIdentifier)
        XCTAssertFalse(credentials.deviceIdentifier.isEmpty)
        XCTAssertNotNil(credentials.bundleIdentifier)
        XCTAssertFalse(credentials.bundleIdentifier.isEmpty)
    }
    
    func testDeviceIdentifierGeneration() {
        let credentials1 = CourierPostAuthIdentifiers(
            userIdentifier: "user1",
            deviceIdentifier: UUID().uuidString,
            ownerType: "clickstream"
        )
        let credentials2 = CourierPostAuthIdentifiers(
            userIdentifier: "user2",
            deviceIdentifier: UUID().uuidString,
            ownerType: "clickstream"
        )
        
        XCTAssertNotEqual(credentials1.deviceIdentifier, credentials2.deviceIdentifier)
        XCTAssertTrue(credentials1.deviceIdentifier.count > 0)
        XCTAssertTrue(credentials2.deviceIdentifier.count > 0)
    }
    
    func testDeviceIdentifierFallbackGeneration() {
        let credentials = CourierPostAuthIdentifiers(userIdentifier: "testUser", ownerType: "clickstream")
        
        XCTAssertFalse(credentials.deviceIdentifier.isEmpty)
        XCTAssertTrue(credentials.deviceIdentifier.count >= 36)
    }
    
    func testUserIdentifierValidation() {
        let emptyUserCredentials = CourierPostAuthIdentifiers(userIdentifier: "", ownerType: "clickstream")
        let validUserCredentials = CourierPostAuthIdentifiers(userIdentifier: "validUser", ownerType: "clickstream")
        
        XCTAssertEqual(emptyUserCredentials.userIdentifier, "")
        XCTAssertEqual(emptyUserCredentials.ownerType, "clickstream")
        XCTAssertEqual(validUserCredentials.userIdentifier, "validUser")
        XCTAssertEqual(validUserCredentials.ownerType, "clickstream")
    }
}
