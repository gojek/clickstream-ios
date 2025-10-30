//
//  SharedClickstreamDependenciesTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 03/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class SharedClickstreamDependenciesTests: XCTestCase {
    
    private var dummyRequest: URLRequest!
    private var constraints: ClickstreamConstraints!
    private var eventClassifier: ClickstreamEventClassification!
    private var prioritiesMock: [Priority]!
    
    override func setUp() {
        // given
        dummyRequest = URLRequest(url: URL(string: "dummy_url")!)
        self.prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1),
        Priority(priority: 1, identifier: "standard")]
        
        self.constraints = ClickstreamConstraints(maxConnectionRetries: 15, maxConnectionRetryInterval: 5, maxRetryIntervalPostPrematureDisconnection: 10, maxRetriesPostPrematureDisconnection: 20, maxPingInterval: 15, priorities: prioritiesMock, flushOnBackground: true, connectionTerminationTimerWaitTime: 2, maxRequestAckTimeout: 3, maxRetriesPerBatch: 10, maxRetryCacheSize: 100000, connectionRetryDuration: 3, flushOnAppLaunch: false, minBatteryLevelPercent: 10.0)
        
        let eventClassifierMock = ClickstreamEventClassification.EventClassifier(identifier: "ClickstreamTestRealtime", eventNames: ["CardEvent"], csEventNames: ["GoChat", "GoPay"])
        self.eventClassifier = ClickstreamEventClassification(eventTypes: [eventClassifierMock])
    }
    
    override func tearDown() {
        self.dummyRequest = nil
        self.prioritiesMock = nil
        self.constraints = nil
        self.eventClassifier = nil
    }
    
    func testNetworkBuilder() {
        // when
        let clickStreamDependencies = try! SharedClickstreamDependencies(with: dummyRequest, networkOptions: ClickstreamNetworkOptions())
        
        // then
        XCTAssertNotNil(clickStreamDependencies.networkBuilder)
        XCTAssertTrue(clickStreamDependencies.networkBuilder is WebsocketNetworkBuilder)
    }

    func testEventWarehouser() {
        // when
        let clickStreamDependencies = try! SharedClickstreamDependencies(with: dummyRequest, networkOptions: ClickstreamNetworkOptions())
        
        // then
        XCTAssertNotNil(clickStreamDependencies.eventWarehouser)
    }
    
    func testEventProcessor() {
        // given
        Clickstream.configurations = ClickstreamConstraints()
        Clickstream.eventClassifier = ClickstreamEventClassification()
        
        // when
        let clickStreamDependencies = try! SharedClickstreamDependencies(with: dummyRequest, networkOptions: ClickstreamNetworkOptions())
        
        // then
        XCTAssertNotNil(clickStreamDependencies.eventProcessor)
    }
    
    func testConfigureCourierSession() async {
        // given
        Clickstream.configurations = ClickstreamConstraints()
        Clickstream.eventClassifier = ClickstreamEventClassification()
        
        // when
        let connectConfig = ClickstreamCourierConnectConfig(baseURL: "https://auth.mqtt.com", authURLPath: "/token", authURLQueries: "source=clickstream")
        let courierConfig = ClickstreamCourierConfig(connectConfig: connectConfig)
        let networkOptions = ClickstreamNetworkOptions(courierConfig: courierConfig)
        let clickStreamDependencies = try! SharedClickstreamDependencies(with: dummyRequest, networkOptions: networkOptions)
        let credentials = CourierIdentifiers(userIdentifier: "12345")
        let topic = "clickstream/topic"
        
        clickStreamDependencies.provideClientIdentifiers(with: credentials, topic: topic)

        // then
        XCTAssertNotNil(clickStreamDependencies.eventProcessor)
    }
}
