//
//  ClickStreamDependenciesTests.swift
//  ClickStreamTests
//
//  Created by Abhijeet Mallick on 29/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import XCTest

class ClickStreamDependenciesTests: XCTestCase {
    
    private var networkConfigurations: NetworkConfigurations!
    private var constraints: ClickStreamConstraints!
    private var eventClassifier: ClickStreamEventClassification!
    private var prioritiesMock: [Priority]!
    
    override func setUp() {
        // given
        let accessToken = "dummy_token"
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let url = URL(string: "ws://mock.clickstream.com/events")!
        self.networkConfigurations = NetworkConfigurations(baseURL: url, headers: headers)
        self.prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1),
        Priority(priority: 1, identifier: "standard")]
        
        self.constraints = ClickStreamConstraints(maxConnectionRetries: 15, maxConnectionRetryInterval: 5, maxRetryIntervalPostPrematureDisconnection: 10, maxRetriesPostPrematureDisconnection: 20, maxPingInterval: 15, priorities: prioritiesMock, flushOnBackground: true, connectionTerminationTimerWaitTime: 2, maxRequestAckTimeout: 3, maxRetriesPerBatch: 10, maxRetryCacheSize: 100000, connectionRetryDuration: 3)
        
        let eventClassifierMock = ClickStreamEventClassification.EventClassifier(identifier: "ClickStreamTestRealtime", eventNames: ["gojek.clickstream.products.events.AdCardEvent"])
        self.eventClassifier = ClickStreamEventClassification(eventTypes: [eventClassifierMock])
    }
    
    override func tearDown() {
        self.networkConfigurations = nil
        self.prioritiesMock = nil
        self.constraints = nil
        self.eventClassifier = nil
    }
    
    func testNetworkBuilder() {
        // when
        let clickStreamDependencies = try! DefaultClickStreamDependencies(with: self.networkConfigurations)
        
        // then
        XCTAssertNotNil(clickStreamDependencies.networkBuilder)
    }
    
    func testEventWarehouser() {
        // when
        let clickStreamDependencies = try! DefaultClickStreamDependencies(with: self.networkConfigurations)
        
        // then
        XCTAssertNotNil(clickStreamDependencies.eventWarehouser)
    }
    
    func testEventProcessor() {
        // given
        ClickStream.constraints = MockConstants.constraints
        ClickStream.eventClassifier = MockConstants.eventClassification
        
        // when
        let clickStreamDependencies = try! DefaultClickStreamDependencies(with: self.networkConfigurations)
        
        // then
        XCTAssertNotNil(clickStreamDependencies.eventProcessor)
    }
}
