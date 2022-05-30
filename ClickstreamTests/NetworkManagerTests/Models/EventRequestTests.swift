//
//  EventRequestTests.swift
//  ClickStreamTests
//
//  Created by Anirudh Vyas on 06/10/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import SwiftProtobuf

class EventRequestTests: XCTestCase {

    func test_batchSentTimeRefresh_whenMockDataWithOldTimeStampIsPassed() {
        
//        let expectation = self.expectation(description: "Updated time must be greater than original time")
//        var originalTime: Google_Protobuf_Timestamp!
//        
//        let eventRequestProto = Gojek_Clickstream_De_EventRequest.with {
//            $0.reqGuid = UUID().uuidString
//            $0.sentTime = Google_Protobuf_Timestamp(date: Date())
//            originalTime = $0.sentTime //recording the original time
//        }
//        
//        let protoData: Data = try! eventRequestProto.serializedData()
//        var sut = EventRequest(guid: "", data: protoData)
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            try! sut.refreshBatchSentTimeStamp()
//            let deserialisedProto = try! Gojek_Clickstream_De_EventRequest(serializedData: sut.data!)
//            XCTAssertLessThan(originalTime.seconds, deserialisedProto.sentTime.seconds)
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 4.0)
    }
}
