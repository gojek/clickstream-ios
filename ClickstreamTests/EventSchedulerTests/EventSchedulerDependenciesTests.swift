//
//  EventSchedulerDependenciesTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 29/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class EventSchedulerDependenciesTests: XCTestCase {

    private let database = try! DefaultDatabase(qos: .WAL)
    private let dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
    private let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
    private let realTimeEvent = Event(guid: "", timestamp: Date(), type: "realTime", eventProtoData: Data())
    
    func testInit() {
        // given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: mockQueue)
        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAliveService = DefaultKeepAliveService(with: mockQueue, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))
        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: mockQueue, persistence: persistence, keepAliveService: keepAliveService)
        
        let networkBuildable: NetworkBuildable = DefaultNetworkBuilder.init(networkConfigs: config, retryMech: retryMech, performOnQueue: mockQueue)

        // when
        let schedulerDependencies = EventSchedulerDependencies(with: networkBuildable, db: database)
        
        // then
        let sut = schedulerDependencies.makeEventWarehouser()
        
        XCTAssertNotNil(sut)
    }
}
