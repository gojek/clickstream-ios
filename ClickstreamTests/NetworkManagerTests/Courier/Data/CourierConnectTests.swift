//
//  CourierConnectTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 15/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class CourierConnectTests: XCTestCase {
    
    func testInitWithAllParameters() {
        let broker = CourierConnect.Broker(host: "mqtt.example.com", port: 1883)
        let expiryDate = Date()
        let connect = CourierConnect(
            token: "test-token-123",
            broker: broker,
            expiryInSec: 3600,
            expiryTimestamp: expiryDate
        )
        
        XCTAssertEqual(connect.token, "test-token-123")
        XCTAssertEqual(connect.broker.host, "mqtt.example.com")
        XCTAssertEqual(connect.broker.port, 1883)
        XCTAssertEqual(connect.expiryInSec, 3600)
        XCTAssertEqual(connect.expiryTimestamp, expiryDate)
    }
    
    func testDecodingWithValidJSON() throws {
        let json = """
        {
            "token": "valid-token",
            "broker": {
                "host": "broker.example.com",
                "port": 8883
            },
            "expiry_in_sec": 7200,
            "expiryTimestamp": 1697356800
        }
        """.data(using: .utf8)!
        
        let connect = try JSONDecoder().decode(CourierConnect.self, from: json)
        
        XCTAssertEqual(connect.token, "valid-token")
        XCTAssertEqual(connect.broker.host, "broker.example.com")
        XCTAssertEqual(connect.broker.port, 8883)
        XCTAssertEqual(connect.expiryInSec, 7200)
    }
    
    func testDecodingWithMissingFields() throws {
        let json = """
        {}
        """.data(using: .utf8)!
        
        let connect = try JSONDecoder().decode(CourierConnect.self, from: json)
        
        XCTAssertEqual(connect.token, "")
        XCTAssertEqual(connect.broker.host, "")
        XCTAssertEqual(connect.broker.port, 0)
        XCTAssertEqual(connect.expiryInSec, 0)
        XCTAssertNil(connect.expiryTimestamp)
    }
    
    func testDecodingWithPartialBrokerData() throws {
        let json = """
        {
            "token": "partial-token",
            "broker": {
                "host": "partial.host.com"
            },
            "expiry_in_sec": 1800
        }
        """.data(using: .utf8)!
        
        let connect = try JSONDecoder().decode(CourierConnect.self, from: json)
        
        XCTAssertEqual(connect.token, "partial-token")
        XCTAssertEqual(connect.broker.host, "partial.host.com")
        XCTAssertEqual(connect.broker.port, 0)
        XCTAssertEqual(connect.expiryInSec, 1800)
    }
    
    func testEncoding() throws {
        let broker = CourierConnect.Broker(host: "encode.test.com", port: 9001)
        let connect = CourierConnect(
            token: "encode-token",
            broker: broker,
            expiryInSec: 5400
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(connect)
        let decoded = try JSONDecoder().decode(CourierConnect.self, from: data)
        
        XCTAssertEqual(decoded.token, connect.token)
        XCTAssertEqual(decoded.broker.host, connect.broker.host)
        XCTAssertEqual(decoded.broker.port, connect.broker.port)
        XCTAssertEqual(decoded.expiryInSec, connect.expiryInSec)
    }
    
    func testBrokerInitialization() {
        let broker = CourierConnect.Broker(host: "test.broker.io", port: 1883)
        
        XCTAssertEqual(broker.host, "test.broker.io")
        XCTAssertEqual(broker.port, 1883)
    }
    
    func testBrokerDecodingWithMissingPort() throws {
        let json = """
        {
            "host": "onlyhost.com"
        }
        """.data(using: .utf8)!
        
        let broker = try JSONDecoder().decode(CourierConnect.Broker.self, from: json)
        
        XCTAssertEqual(broker.host, "onlyhost.com")
        XCTAssertEqual(broker.port, 0)
    }
}
