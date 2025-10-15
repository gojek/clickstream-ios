//
//  CourierMessageAdapterTypeTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 15/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import CourierMQTT
import CourierProtobuf

class CourierMessageAdapterTypeTests: XCTestCase {
    
    func testRawValueInitialization() {
        XCTAssertEqual(CourierMessageAdapterType.json.rawValue, "json")
        XCTAssertEqual(CourierMessageAdapterType.protobuf.rawValue, "protobuf")
        XCTAssertEqual(CourierMessageAdapterType.data.rawValue, "data")
        XCTAssertEqual(CourierMessageAdapterType.text.rawValue, "text")
        XCTAssertEqual(CourierMessageAdapterType.plist.rawValue, "plist")
    }
    
    func testDecodingFromJSON() throws {
        let jsonData = """
        "json"
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(CourierMessageAdapterType.self, from: jsonData)
        XCTAssertEqual(decoded, .json)
    }
    
    func testDecodingAllTypes() throws {
        let types = ["json", "protobuf", "data", "text", "plist"]
        let expected: [CourierMessageAdapterType] = [.json, .protobuf, .data, .text, .plist]
        
        for (index, typeString) in types.enumerated() {
            let jsonData = "\"\(typeString)\"".data(using: .utf8)!
            let decoded = try JSONDecoder().decode(CourierMessageAdapterType.self, from: jsonData)
            XCTAssertEqual(decoded, expected[index])
        }
    }
    
    func testMappedAdapterForJSON() {
        let adapter = CourierMessageAdapterType.mapped(from: .json)
        XCTAssertTrue(adapter is JSONMessageAdapter)
    }
    
    func testMappedAdapterForProtobuf() {
        let adapter = CourierMessageAdapterType.mapped(from: .protobuf)
        XCTAssertTrue(adapter is ProtobufMessageAdapter)
    }
    
    func testMappedAdapterForData() {
        let adapter = CourierMessageAdapterType.mapped(from: .data)
        XCTAssertTrue(adapter is DataMessageAdapter)
    }
    
    func testMappedAdapterForText() {
        let adapter = CourierMessageAdapterType.mapped(from: .text)
        XCTAssertTrue(adapter is TextMessageAdapter)
    }
    
    func testMappedAdapterForPlist() {
        let adapter = CourierMessageAdapterType.mapped(from: .plist)
        XCTAssertTrue(adapter is PlistMessageAdapter)
    }
    
    func testAllTypesReturnValidAdapters() {
        let allTypes: [CourierMessageAdapterType] = [.json, .protobuf, .data, .text, .plist]
        
        for type in allTypes {
            let adapter = CourierMessageAdapterType.mapped(from: type)
            XCTAssertNotNil(adapter, "Adapter should not be nil for type: \(type)")
        }
    }
    
    func testInvalidDecodingThrowsError() {
        let invalidJSON = """
        "invalid_type"
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(CourierMessageAdapterType.self, from: invalidJSON))
    }
}
