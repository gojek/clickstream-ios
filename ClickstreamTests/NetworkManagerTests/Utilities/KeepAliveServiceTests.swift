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
        let sut = DefaultKeepAliveServiceWithSafeTimer(with: mockQueue, duration: 2.0, reachability: NetworkReachabilityMock(isReachable: true))
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
        let expectation = self.expectation(description: "Should not receive callbacks after stop")
        // Only read and written on mockQueue, where the subscriber is invoked.
        var callbackCount = 0
        let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.keepAlive", qos: .utility)

        let sut = DefaultKeepAliveServiceWithSafeTimer(with: mockQueue, duration: 0.5, reachability: NetworkReachabilityMock(isReachable: true))

        //when
        sut.start {
            callbackCount += 1
        }

        // Assert on behaviour rather than an exact tick count, which depends on scheduler timing.
        mockQueue.asyncAfter(deadline: .now() + 2.0) {
            sut.stop()
            // Let any tick that fired just before stop() finish delivering.
            mockQueue.asyncAfter(deadline: .now() + 0.5) {
                let countAfterStop = callbackCount
                XCTAssertGreaterThan(countAfterStop, 0, "Timer should have fired before being stopped")
                mockQueue.asyncAfter(deadline: .now() + 2.0) {
                    XCTAssertEqual(callbackCount, countAfterStop, "No callbacks expected after stop")
                    expectation.fulfill()
                }
            }
        }
        //then
        wait(for: [expectation], timeout: 15)
    }
}
