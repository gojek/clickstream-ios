//
//  SchedulerServiceTests.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 20/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class SchedulerServiceTests: XCTestCase {

    func test_whenTimerTriggeredOnOneQueue_shouldRespondOnTheGivenQueue() {
        //given
        let expectation = self.expectation(description: "Should respond on the given queue")
        
        let schedulerQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.schedule", qos: .utility)
        let prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1)]
        
        SerialQueue.registerDetection(of: schedulerQueueMock) //Registers a queue to be detected.
        let sut = DefaultSchedulerService(with: prioritiesMock, performOnQueue: schedulerQueueMock)
        sut.subscriber = { priority in
            let queueName = SerialQueue.currentQueueLabel ?? ""
            XCTAssertEqual(queueName, "com.mock.gojek.clickstream.schedule")
            expectation.fulfill()
        }
        //when
        sut.start()
        wait(for: [expectation], timeout: 2)
    }
    
    func test_whenServiceIsStopped_thenNoCallbackMustBeReceived() {
        //given
        let expectation = self.expectation(description: "Should not exceed the number of callbacks")
        var callbackCount = 0
        let schedulerQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.schedule", qos: .utility)
        let prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1)]
        
        let sut = DefaultSchedulerService(with: prioritiesMock, performOnQueue: schedulerQueueMock)

        sut.subscriber = { priority in
            callbackCount += 1
        }
        
        //when
        sut.start()
        schedulerQueueMock.asyncAfter(deadline: .now() + 4.5) {
            sut.stop()
            schedulerQueueMock.asyncAfter(deadline: .now() + 2.0) {
                XCTAssertEqual(callbackCount, 4)
                expectation.fulfill()
            }
        }
        //then
        wait(for: [expectation], timeout: 7)
    }
    
    func test_whenMultiplePrioritiesAreGiven_thenThereMustBeMultipleCallbacks() {
        //given
        let expectation = self.expectation(description: "Callbacks must be multiple of the priorites")
        let schedulerQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.schedule", qos: .utility)
        let prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1),
                              Priority(priority: 1, identifier: "standard", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1)]
        
        let sut = DefaultSchedulerService(with: prioritiesMock, performOnQueue: schedulerQueueMock)
        
        var callbackPriorities = Set<String>()
        sut.subscriber = { priority in
            callbackPriorities.insert(priority.identifier)
        }
        
        //when
        sut.start()
        schedulerQueueMock.asyncAfter(deadline: .now() + 2.0) {
            sut.stop()
            XCTAssertEqual(callbackPriorities.count, prioritiesMock.count)
            expectation.fulfill()
        }
        //then
        wait(for: [expectation], timeout: 3)
    }
}

