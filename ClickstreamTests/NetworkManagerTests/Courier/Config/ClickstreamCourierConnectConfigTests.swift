//
//  ClickstreamCourierConnectConfigTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 15/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class ClickstreamCourierConnectConfigTests: XCTestCase {
    
    func testInitWithAllParameters() {
        let config = ClickstreamCourierConnectConfig(
            enableAuthenticationTimeout: true,
            authenticationTimeoutInterval: 30.0,
            autoReconnectInterval: 1.0,
            maxAutoReconnectInterval: 30.0,
            tokenCachingType: 2,
            tokenExpiryMins: 120.0,
            alpn: ["h2", "http/1.1"]
        )

        XCTAssertEqual(config.autoReconnectInterval, 1.0)
        XCTAssertEqual(config.maxAutoReconnectInterval, 30.0)
        XCTAssertEqual(config.authenticationTimeoutInterval, 30.0)
        XCTAssertEqual(config.enableAuthenticationTimeout, true)
        XCTAssertEqual(config.tokenCachingType, 2)
        XCTAssertEqual(config.tokenExpiryMins, 120.0)
        XCTAssertTrue(config.isTokenCacheExpiryEnabled)
        XCTAssertEqual(config.alpn, ["h2", "http/1.1"])
    }
    
    func testInitWithDefaultParameters() {
        let config = ClickstreamCourierConnectConfig()

        XCTAssertEqual(config.autoReconnectInterval, 5.0)
        XCTAssertEqual(config.maxAutoReconnectInterval, 10.0)
        XCTAssertEqual(config.authenticationTimeoutInterval, 20.0)
        XCTAssertEqual(config.enableAuthenticationTimeout, true)
        XCTAssertEqual(config.tokenCachingType, 2)
        XCTAssertEqual(config.tokenExpiryMins, 360.0)
        XCTAssertTrue(config.isTokenCacheExpiryEnabled)
        XCTAssertFalse(config.alpn.isEmpty)
    }

    func testDecodingWithValidData() throws {
        let json = """
        {
            "token_expiry_mins": 90.5,
            "token_expiry_cache_enabled": false,
            "alpn": ["mqtt", "h2"]
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConnectConfig.self, from: json)

        XCTAssertEqual(config.tokenExpiryMins, 90.5)
        XCTAssertFalse(config.isTokenCacheExpiryEnabled)
        XCTAssertEqual(config.alpn, ["mqtt", "h2"])
    }
    
    func testDecodingWithMissingOptionalFields() throws {
        let json = """
        {}
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConnectConfig.self, from: json)
    
        XCTAssertEqual(config.tokenExpiryMins, 360.0)
        XCTAssertFalse(config.isTokenCacheExpiryEnabled)
        XCTAssertTrue(config.alpn.isEmpty)
    }
    
    func testALPNArrayHandling() throws {
        let emptyArrayJSON = """
        {
            "alpn": []
        }
        """.data(using: .utf8)!
        
        let multipleValuesJSON = """
        {
            "alpn": ["http/1.1", "h2", "mqtt"]
        }
        """.data(using: .utf8)!
        
        let emptyConfig = try JSONDecoder().decode(ClickstreamCourierConnectConfig.self, from: emptyArrayJSON)
        let multiConfig = try JSONDecoder().decode(ClickstreamCourierConnectConfig.self, from: multipleValuesJSON)
        
        XCTAssertTrue(emptyConfig.alpn.isEmpty)
        XCTAssertEqual(multiConfig.alpn.count, 3)
        XCTAssertEqual(multiConfig.alpn, ["http/1.1", "h2", "mqtt"])
    }
}
