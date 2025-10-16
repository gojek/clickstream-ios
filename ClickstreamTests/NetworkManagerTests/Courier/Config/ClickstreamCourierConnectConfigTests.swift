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
            baseURL: "https://mqtt.example.com",
            authURLPath: "/v2/auth",
            tokenExpiryMins: 120.0,
            pingIntervalMs: 500.0,
            isCleanSessionEnabled: true,
            isTokenCacheExpiryEnabled: true,
            alpn: ["h2", "http/1.1"]
        )
        
        XCTAssertEqual(config.baseURL, "https://mqtt.example.com")
        XCTAssertEqual(config.authURLPath, "/v2/auth")
        XCTAssertEqual(config.tokenExpiryMins, 120.0)
        XCTAssertEqual(config.pingIntervalMs, 500.0)
        XCTAssertTrue(config.isCleanSessionEnabled)
        XCTAssertTrue(config.isTokenCacheExpiryEnabled)
        XCTAssertEqual(config.alpn, ["h2", "http/1.1"])
    }
    
    func testInitWithDefaultParameters() {
        let config = ClickstreamCourierConnectConfig()
        
        XCTAssertEqual(config.baseURL, "")
        XCTAssertEqual(config.authURLPath, "")
        XCTAssertEqual(config.tokenExpiryMins, 36.0)
        XCTAssertEqual(config.pingIntervalMs, 10.0)
        XCTAssertFalse(config.isCleanSessionEnabled)
        XCTAssertFalse(config.isTokenCacheExpiryEnabled)
        XCTAssertTrue(config.alpn.isEmpty)
    }
    
    func testDecodingValidationFailure() {
        let jsonWithEmptyURL = """
        {
            "base_url": "",
            "auth_url_path": "/auth"
        }
        """.data(using: .utf8)!
        
        let jsonWithEmptyPath = """
        {
            "base_url": "https://api.test.com",
            "auth_url_path": ""
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(ClickstreamCourierConnectConfig.self, from: jsonWithEmptyURL))
        XCTAssertThrowsError(try JSONDecoder().decode(ClickstreamCourierConnectConfig.self, from: jsonWithEmptyPath))
    }
    
    func testDecodingWithValidData() throws {
        let json = """
        {
            "base_url": "https://secure.mqtt.com",
            "auth_url_path": "/authenticate",
            "token_expiry_mins": 90.5,
            "ping_interval_ms": "350",
            "clean_session_enabled": true,
            "token_expiry_cache_enabled": false,
            "alpn": ["mqtt", "h2"]
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConnectConfig.self, from: json)
        
        XCTAssertEqual(config.baseURL, "https://secure.mqtt.com")
        XCTAssertEqual(config.authURLPath, "/authenticate")
        XCTAssertEqual(config.tokenExpiryMins, 90.5)
        XCTAssertEqual(config.pingIntervalMs, 350.0)
        XCTAssertTrue(config.isCleanSessionEnabled)
        XCTAssertFalse(config.isTokenCacheExpiryEnabled)
        XCTAssertEqual(config.alpn, ["mqtt", "h2"])
    }
    
    func testDecodingWithMissingOptionalFields() throws {
        let json = """
        {
            "base_url": "https://minimal.test.com",
            "auth_url_path": "/minimal"
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConnectConfig.self, from: json)
        
        XCTAssertEqual(config.baseURL, "https://minimal.test.com")
        XCTAssertEqual(config.authURLPath, "/minimal")
        XCTAssertEqual(config.tokenExpiryMins, 360.0)
        XCTAssertEqual(config.pingIntervalMs, 240.0)
        XCTAssertFalse(config.isCleanSessionEnabled)
        XCTAssertFalse(config.isTokenCacheExpiryEnabled)
        XCTAssertTrue(config.alpn.isEmpty)
    }
    
    func testTimeIntervalDecoding() throws {
        let json = """
        {
            "base_url": "https://time.test.com",
            "auth_url_path": "/time",
            "token_expiry_mins": "180",
            "ping_interval_ms": 1000
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(ClickstreamCourierConnectConfig.self, from: json)
        
        XCTAssertEqual(config.tokenExpiryMins, 180.0)
        XCTAssertEqual(config.pingIntervalMs, 1000.0)
    }
    
    func testALPNArrayHandling() throws {
        let emptyArrayJSON = """
        {
            "base_url": "https://alpn.test.com",
            "auth_url_path": "/alpn",
            "alpn": []
        }
        """.data(using: .utf8)!
        
        let multipleValuesJSON = """
        {
            "base_url": "https://alpn2.test.com",
            "auth_url_path": "/alpn2",
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
