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

    func testMakeCourierNetworkBuilder() throws {
        // given
        let dummyRequest = URLRequest(url: URL(string: "dummy_url")!)
        Clickstream.configurations = MockConstants.constraints
        Clickstream.eventClassifier = MockConstants.eventClassification
        // when
        let networkManagerDependencies = NetworkManagerDependencies(with: dummyRequest,
                                                                    db: database,
                                                                    networkOptions: ClickstreamNetworkOptions())
        
        let networkBuilder: any NetworkBuildable = networkManagerDependencies.makeCourierNetworkBuilder()
        
        // then
        XCTAssertNotNil(networkBuilder)
    }

}
