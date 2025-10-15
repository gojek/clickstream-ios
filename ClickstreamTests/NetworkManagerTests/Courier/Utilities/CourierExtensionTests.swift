//
//  CourierExtensionTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 15/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import CourierCore

class CourierExtensionTests: XCTestCase {
    
    func testTimeIntervalDecoding() {
        struct TestStruct: Codable {
            let timeInterval: TimeInterval?
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                timeInterval = container.decodeTimeIntervalIfPresent(forKey: .timeInterval)
            }
            
            private enum CodingKeys: String, CodingKey {
                case timeInterval
            }
        }
        
        let doubleJSON = """
        {"timeInterval": 123.45}
        """.data(using: .utf8)!
        
        let intJSON = """
        {"timeInterval": 123}
        """.data(using: .utf8)!
        
        let stringJSON = """
        {"timeInterval": "123.45"}
        """.data(using: .utf8)!
        
        let invalidStringJSON = """
        {"timeInterval": "invalid"}
        """.data(using: .utf8)!
        
        let missingJSON = """
        {}
        """.data(using: .utf8)!
        
        do {
            let doubleResult = try JSONDecoder().decode(TestStruct.self, from: doubleJSON)
            XCTAssertEqual(doubleResult.timeInterval, 123.45)
            
            let intResult = try JSONDecoder().decode(TestStruct.self, from: intJSON)
            XCTAssertEqual(intResult.timeInterval, 123.0)
            
            let stringResult = try JSONDecoder().decode(TestStruct.self, from: stringJSON)
            XCTAssertEqual(stringResult.timeInterval, 123.45)
            
            let invalidStringResult = try JSONDecoder().decode(TestStruct.self, from: invalidStringJSON)
            XCTAssertNil(invalidStringResult.timeInterval)
            
            let missingResult = try JSONDecoder().decode(TestStruct.self, from: missingJSON)
            XCTAssertNil(missingResult.timeInterval)
        } catch {
            XCTFail("Decoding failed: \(error)")
        }
    }

    func testQoSInitialization() {
        XCTAssertEqual(QoS(value: 0), .zero)
        XCTAssertEqual(QoS(value: 1), .one)
        XCTAssertEqual(QoS(value: 2), .two)
        XCTAssertEqual(QoS(value: 3), .oneWithoutPersistenceAndNoRetry)
        XCTAssertEqual(QoS(value: 4), .oneWithoutPersistenceAndRetry)
        
        XCTAssertNil(QoS(value: -1))
        XCTAssertNil(QoS(value: 5))
        XCTAssertNil(QoS(value: 100))
    }
}
