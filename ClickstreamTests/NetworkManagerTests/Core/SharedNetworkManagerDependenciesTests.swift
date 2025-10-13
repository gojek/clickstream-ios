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

    func testMakeNetworkBuilderWithEmptyConfigs() throws {
        // given
        let dummyRequest = URLRequest(url: URL(string: "dummy_url")!)

        Clickstream.configurations = MockConstants.constraints
        Clickstream.eventClassifier = MockConstants.eventClassification
        // when
        let networkManagerDependencies = SharedNetworkManagerDependencies(with: dummyRequest, db: database, courierConfig: ClickstreamCourierConfig())
        
        let networkBuilder: NetworkBuildable = networkManagerDependencies.makeNetworkBuilder()
        
        // then
        XCTAssertNotNil(networkBuilder)
        XCTAssertTrue(networkBuilder is WebsocketNetworkBuilder)
    }
}
