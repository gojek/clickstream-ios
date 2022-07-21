//
//  NetworkManagerDependenciesTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 30/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import XCTest

class NetworkManagerDependenciesTests: XCTestCase {

    private let database = try! DefaultDatabase(qos: .WAL)

    func testMakeNetworkBuilder() throws {
        // given
        let dummyRequest = URLRequest(url: URL(string: "ws://mock.clickstream.com/events")!)
        Clickstream.constraints = MockConstants.constraints
        Clickstream.eventClassifier = MockConstants.eventClassification
        // when
        let networkManagerDependencies = NetworkManagerDependencies(with: dummyRequest, db: database)
        
        let networkBuilder: NetworkBuildable = networkManagerDependencies.makeNetworkBuilder()
        
        // then
        XCTAssertNotNil(networkBuilder)
    }
}
