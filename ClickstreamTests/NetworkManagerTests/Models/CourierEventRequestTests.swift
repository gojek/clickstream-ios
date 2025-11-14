//
//  CourierEventRequestTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 14/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import SwiftProtobuf

class CourierEventRequestTests: XCTestCase {

    func test_batchSentTimeRefresh_whenMockDataWithOldTimeStampIsPassed() {
        let originalDate = Date()
        let eventRequestProto = Odpf_Raccoon_EventRequest.with {
            $0.reqGuid = UUID().uuidString
            $0.sentTime = Google_Protobuf_Timestamp(date: originalDate)
        }
        
        let protoData = try! eventRequestProto.serializedData()
        var sut = CourierEventRequest(guid: UUID().uuidString, data: protoData)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        try! sut.refreshBatchSentTimeStamp()
        
        let updatedProto = try! Odpf_Raccoon_EventRequest(serializedBytes: sut.data!)
        let updatedDate = updatedProto.sentTime.date
        
        XCTAssertGreaterThan(updatedDate, originalDate)
    }
    
    func test_batchSentTimeRefresh_whenDataIsNil() {
        var sut = CourierEventRequest(guid: UUID().uuidString, data: nil)
        
        XCTAssertNoThrow(try sut.refreshBatchSentTimeStamp())
    }
    
    func test_bumpRetriesMade() {
        var sut = CourierEventRequest(guid: UUID().uuidString)
        let initialRetries = sut.retriesMade
        
        sut.bumpRetriesMade()
        
        XCTAssertEqual(sut.retriesMade, initialRetries + 1)
    }
    
    func test_refreshCachingTimeStamp() {
        var sut = CourierEventRequest(guid: UUID().uuidString)
        let originalTimestamp = sut.timeStamp
        
        Thread.sleep(forTimeInterval: 0.1)
        sut.refreshCachingTimeStamp()
        
        XCTAssertGreaterThan(sut.timeStamp, originalTimestamp)
    }
    
    func test_initialization() {
        let guid = UUID().uuidString
        let testData = "test data".data(using: .utf8)
        
        let sut = CourierEventRequest(guid: guid, data: testData)
        
        XCTAssertEqual(sut.guid, guid)
        XCTAssertEqual(sut.data, testData)
        XCTAssertEqual(sut.retriesMade, 0)
        XCTAssertEqual(sut.isInternal, false)
        XCTAssertEqual(sut.eventType, .realTime)
        XCTAssertEqual(sut.eventCount, 0)
        XCTAssertNotNil(sut.createdTimestamp)
    }
    
    func test_equality() {
        let guid = UUID().uuidString
        let sut1 = CourierEventRequest(guid: guid)
        let sut2 = CourierEventRequest(guid: guid)
        let sut3 = CourierEventRequest(guid: UUID().uuidString)
        
        XCTAssertEqual(sut1, sut2)
        XCTAssertNotEqual(sut1, sut3)
    }
    
    func test_tableName() {
        XCTAssertEqual(CourierEventRequest.tableName, "courier_eventRequest")
    }
    
    func test_primaryKey() {
        XCTAssertEqual(CourierEventRequest.primaryKey, "guid")
    }
    
    func test_tableMigrations() {
        let migrations = CourierEventRequest.tableMigrations
        XCTAssertNil(migrations)
    }
}
