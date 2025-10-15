//
//  CourierIdleActivityTimeoutPolicyTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 15/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class CourierIdleActivityTimeoutPolicyTests: XCTestCase {
    
    func testDecodingWithAllValues() throws {
        let json = """
        {
            "is_enabled": true,
            "timer_interval": 15.0,
            "inactivity_timeout": 20.0,
            "read_timeout": 50.0
        }
        """.data(using: .utf8)!
        
        let policy = try JSONDecoder().decode(CourierIdleActivityTimeoutPolicy.self, from: json)
        
        XCTAssertTrue(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 15.0)
        XCTAssertEqual(policy.inactivityTimeout, 20.0)
        XCTAssertEqual(policy.readTimeout, 50.0)
    }
    
    func testDecodingWithDefaultValues() throws {
        let json = """
        {}
        """.data(using: .utf8)!
        
        let policy = try JSONDecoder().decode(CourierIdleActivityTimeoutPolicy.self, from: json)
        
        XCTAssertFalse(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 12.0)
        XCTAssertEqual(policy.inactivityTimeout, 10.0)
        XCTAssertEqual(policy.readTimeout, 40.0)
    }
    
    func testDecodingWithPartialValues() throws {
        let json = """
        {
            "is_enabled": true,
            "timer_interval": 25.5
        }
        """.data(using: .utf8)!
        
        let policy = try JSONDecoder().decode(CourierIdleActivityTimeoutPolicy.self, from: json)
        
        XCTAssertTrue(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 25.5)
        XCTAssertEqual(policy.inactivityTimeout, 10.0)
        XCTAssertEqual(policy.readTimeout, 40.0)
    }
    
    func testDecodingWithIntegerValues() throws {
        let json = """
        {
            "is_enabled": false,
            "timer_interval": 18,
            "inactivity_timeout": 15,
            "read_timeout": 60
        }
        """.data(using: .utf8)!
        
        let policy = try JSONDecoder().decode(CourierIdleActivityTimeoutPolicy.self, from: json)
        
        XCTAssertFalse(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 18.0)
        XCTAssertEqual(policy.inactivityTimeout, 15.0)
        XCTAssertEqual(policy.readTimeout, 60.0)
    }
    
    func testDecodingWithStringValues() throws {
        let json = """
        {
            "is_enabled": true,
            "timer_interval": "14.5",
            "inactivity_timeout": "8.5",
            "read_timeout": "35.5"
        }
        """.data(using: .utf8)!
        
        let policy = try JSONDecoder().decode(CourierIdleActivityTimeoutPolicy.self, from: json)
        
        XCTAssertTrue(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 14.5)
        XCTAssertEqual(policy.inactivityTimeout, 8.5)
        XCTAssertEqual(policy.readTimeout, 35.5)
    }
    
    func testDecodingWithInvalidStringValues() throws {
        let json = """
        {
            "is_enabled": true,
            "timer_interval": "invalid",
            "inactivity_timeout": "bad_value",
            "read_timeout": "not_a_number"
        }
        """.data(using: .utf8)!
        
        let policy = try JSONDecoder().decode(CourierIdleActivityTimeoutPolicy.self, from: json)
        
        XCTAssertTrue(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 12.0)
        XCTAssertEqual(policy.inactivityTimeout, 10.0)
        XCTAssertEqual(policy.readTimeout, 40.0)
    }
    
    func testDecodingWithMixedValidInvalidValues() throws {
        let json = """
        {
            "is_enabled": false,
            "timer_interval": "16.5",
            "inactivity_timeout": "invalid",
            "read_timeout": 45
        }
        """.data(using: .utf8)!
        
        let policy = try JSONDecoder().decode(CourierIdleActivityTimeoutPolicy.self, from: json)
        
        XCTAssertFalse(policy.isEnabled)
        XCTAssertEqual(policy.timerInterval, 16.5)
        XCTAssertEqual(policy.inactivityTimeout, 10.0)
        XCTAssertEqual(policy.readTimeout, 45.0)
    }
}
