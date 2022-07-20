//
//  KeepAliveServiceTests.swift
//  ClickStreamTests
//
//  Created by Anirudh Vyas on 04/11/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class KeepAliveServiceTests: XCTestCase {

    func test_whenTimerTriggeredOnOneQueue_shouldRespondOnTheGivenQueue() {
        //given
        let expectation = self.expectation(description: "Should respond on the given queue")
        
        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.keepAlive", qos: .utility)
        
        SerialQueue.registerDetection(of: mockQueue) //Registers a queue to be detected.
        let sut = DefaultKeepAliveService(with: mockQueue, duration: 2.0, reachability: NetworkReachabilityMock(isReachable: true))
        //when
        sut.start {
            let queueName = SerialQueue.currentQueueLabel ?? ""
            XCTAssertEqual(queueName, "com.mock.gojek.clickstream.keepAlive")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4)
    }
    
    func test_whenServiceIsStopped_thenNoCallbackMustBeReceived() {
        //given
        let expectation = self.expectation(description: "Should not exceed the number of callbacks")
        var callbackCount = 0
        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.keepAlive", qos: .utility)
        
        let sut = DefaultKeepAliveService(with: mockQueue, duration: 1.0, reachability: NetworkReachabilityMock(isReachable: true))
        
        //when
        sut.start {
            callbackCount += 1
            print(callbackCount)
        }
        
        mockQueue.asyncAfter(deadline: .now() + 4.5) {
            sut.stop()
            mockQueue.asyncAfter(deadline: .now() + 2.0) {
                XCTAssertEqual(callbackCount, 4)
                expectation.fulfill()
            }
        }
        //then
        wait(for: [expectation], timeout: 7)
    }
}
