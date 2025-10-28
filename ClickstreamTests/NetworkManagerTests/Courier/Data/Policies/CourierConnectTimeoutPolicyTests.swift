//
//  CourierConnectTimeoutPolicyTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 15/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class CourierConnectTimeoutPolicyTests: XCTestCase {

    func testDecodingWithAllValues() throws {
        let json = """
        {
            "is_enabled": true,
            "timer_interval": 20.5,
            "timeout": 15.0
        }
        """.data(using: .utf8)!

        let policy = try JSONDecoder().decode(CourierConnectTimeoutPolicy.self, from: json)

        XCTAssertTrue(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 20.5)
        XCTAssertEqual(policy.timeout, 15.0)
    }

    func testDecodingWithDefaultValues() throws {
        let json = """
        {}
        """.data(using: .utf8)!

        let policy = try JSONDecoder().decode(CourierConnectTimeoutPolicy.self, from: json)

        XCTAssertFalse(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 15.0)
        XCTAssertEqual(policy.timeout, 15.0)
    }

    func testDecodingWithPartialValues() throws {
        let json = """
        {
            "is_enabled": true,
            "timer_interval": "25"
        }
        """.data(using: .utf8)!

        let policy = try JSONDecoder().decode(CourierConnectTimeoutPolicy.self, from: json)

        XCTAssertTrue(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 25.0)
        XCTAssertEqual(policy.timeout, 15.0)
    }

    func testDecodingWithIntegerValues() throws {
        let json = """
        {
            "is_enabled": false,
            "timer_interval": 30,
            "timeout": 20
        }
        """.data(using: .utf8)!

        let policy = try JSONDecoder().decode(CourierConnectTimeoutPolicy.self, from: json)

        XCTAssertFalse(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 30.0)
        XCTAssertEqual(policy.timeout, 20.0)
    }

    func testDecodingWithStringValues() throws {
        let json = """
        {
            "is_enabled": true,
            "timer_interval": "18.5",
            "timeout": "12.5"
        }
        """.data(using: .utf8)!

        let policy = try JSONDecoder().decode(CourierConnectTimeoutPolicy.self, from: json)

        XCTAssertTrue(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 18.5)
        XCTAssertEqual(policy.timeout, 12.5)
    }

    func testDecodingWithInvalidStringValues() throws {
        let json = """
        {
            "is_enabled": true,
            "timer_interval": "invalid",
            "timeout": "also_invalid"
        }
        """.data(using: .utf8)!

        let policy = try JSONDecoder().decode(CourierConnectTimeoutPolicy.self, from: json)

        XCTAssertTrue(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 15.0)
        XCTAssertEqual(policy.timeout, 15.0)
    }
}
