//
//  CSBinaryEventTests.swift
//  ClickstreamTests
//
//  Copyright © 2026 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class CSBinaryEventTests: XCTestCase {

    func testInitializationSetsAutoFields() {
        let before = Date()
        let event = CSBinaryEvent(type: "gopay-container-component", encodedData: "dGVzdA==")
        let after = Date()

        XCTAssertFalse(event.guid.isEmpty)
        XCTAssertGreaterThanOrEqual(event.timestamp, before)
        XCTAssertLessThanOrEqual(event.timestamp, after)
    }

    func testInitializationWithRequiredFields() {
        let event = CSBinaryEvent(type: "gopay-container-page", encodedData: "dGVzdA==")

        XCTAssertEqual(event.type, "gopay-container-page")
        XCTAssertEqual(event.encodedData, "dGVzdA==")
        XCTAssertNil(event.product)
    }

    func testInitializationWithProduct() {
        let event = CSBinaryEvent(type: "gopay-container-component", encodedData: "dGVzdA==", product: "gopay")

        XCTAssertEqual(event.product, "gopay")
    }

    func testEachInstanceHasUniqueGuid() {
        let first = CSBinaryEvent(type: "type", encodedData: "dGVzdA==")
        let second = CSBinaryEvent(type: "type", encodedData: "dGVzdA==")

        XCTAssertNotEqual(first.guid, second.guid)
    }
}
