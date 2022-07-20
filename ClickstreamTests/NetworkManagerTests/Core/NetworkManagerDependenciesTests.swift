//
//  NetworkManagerDependenciesTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 30/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class NetworkManagerDependenciesTests: XCTestCase {

    private let database = try! DefaultDatabase(qos: .WAL)

    func testMakeNetworkBuilder() throws {
        // given
        let accessToken = "dummy_token"
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let url = URL(string: "ws://mock.clickstream.com/events")!
        Clickstream.constraints = MockConstants.constraints
        Clickstream.eventClassifier = MockConstants.eventClassification
        let networkConfigurations = NetworkConfigurations(baseURL: url, headers: headers)
        // when
        let networkManagerDependencies = NetworkManagerDependencies(with: networkConfigurations, db: database)
        
        let networkBuilder: NetworkBuildable = networkManagerDependencies.makeNetworkBuilder()
        
        // then
        XCTAssertNotNil(networkBuilder)
    }

}
