//
//  SharedNetworkManagerDependenciesTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 03/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class SharedNetworkManagerDependenciesTests: XCTestCase {

    private let database = try! DefaultDatabase(qos: .WAL)

    func testWebsocketNetworkBuilder() throws {
        // given
        let dummyRequest = URLRequest(url: URL(string: "dummy_url")!)

        Clickstream.configurations = MockConstants.constraints
        Clickstream.eventClassifier = MockConstants.eventClassification

        // when
        let networkManagerDependencies = SharedNetworkManagerDependencies(with: dummyRequest,
                                                                          db: database,
                                                                          networkOptions: .init(isWebsocketEnabled: true, isCourierEnabled: false))
        let networkBuilder: NetworkBuildable = networkManagerDependencies.makeNetworkBuilder()

        // then
        XCTAssertNotNil(networkBuilder)
        XCTAssertTrue(networkBuilder is WebsocketNetworkBuilder)
    }

    func testCurierNetworkBuilder() async  {
        // given
        let dummyRequest = URLRequest(url: URL(string: "dummy_url")!)

        Clickstream.configurations = MockConstants.constraints
        Clickstream.eventClassifier = MockConstants.eventClassification

        // when
        let networkManagerDependencies = SharedNetworkManagerDependencies(with: dummyRequest,
                                                                          db: database,
                                                                          networkOptions: .init(isWebsocketEnabled: false, isCourierEnabled: true))
        let networkBuilder: NetworkBuildable = networkManagerDependencies.makeCourierNetworkBuilder()

        // then
        XCTAssertNotNil(networkBuilder)
        XCTAssertTrue(networkBuilder is CourierNetworkBuilder)
    }
    
    func testConfigureCourierSession() {
        // given
        let expectation = XCTestExpectation(description: "Courier session must be configured")
        let dummyRequest = URLRequest(url: URL(string: "dummy_url")!)
        let user = CourierIdentifiers(userIdentifier: "12345")
        let topic = "clickstream/topic"
        
        Clickstream.configurations = MockConstants.constraints
        Clickstream.eventClassifier = MockConstants.eventClassification

        // when
        let networkManagerDependencies = SharedNetworkManagerDependencies(with: dummyRequest,
                                                                          db: database,
                                                                          networkOptions: .init(isWebsocketEnabled: false, isCourierEnabled: true))
        let networkBuilder: NetworkBuildable = networkManagerDependencies.makeCourierNetworkBuilder()
        networkManagerDependencies.provideClientIdentifiers(with: user, topic: topic)

        XCTAssertNotNil(networkBuilder)
        XCTAssertTrue(networkBuilder is CourierNetworkBuilder)
    }
}
