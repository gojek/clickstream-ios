//
//  EventCreatorTests.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 20/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest


class EventCreatorTests: XCTestCase {

    private let database = try! DefaultDatabase(qos: .WAL)
    private let dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
    private let schedulerQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.schedule", qos: .utility)
    private let networkQueue = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility)
    
    func test_whenReachableMockService_shouldReturnCanForwardAsTrue() {
        //given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: networkQueue)
        let deviceStatus = DefaultDeviceStatus(performOnQueue: networkQueue)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAliveService = DefaultKeepAliveService(with: schedulerQueueMock, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: networkQueue, persistence: persistence,keepAliveService: keepAliveService)
        let networkBuilder = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: networkQueue)
        //when
        let sut = DefaultEventBatchCreator(with: networkBuilder, performOnQueue: schedulerQueueMock)
        //then
        networkQueue.async {
            XCTAssertTrue(sut.canForward)
        }
    }
    
    func test_whenNotReachableMockService_shouldReturnCanForwardAsFalse() {
        //given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        
        let deviceStatus = DefaultDeviceStatus(performOnQueue: networkQueue)
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: networkQueue)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAliveService = DefaultKeepAliveService(with: schedulerQueueMock, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: false), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: networkQueue, persistence: persistence, keepAliveService: keepAliveService)
        let networkBuilder = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: networkQueue)
        //when
        let sut = DefaultEventBatchCreator(with: networkBuilder, performOnQueue: schedulerQueueMock)
        //then
        XCTAssertFalse(sut.canForward)
    }
    
    func test_whenReachableMockService_shouldReturnTrue() {
        //given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        
        let deviceStatus = DefaultDeviceStatus(performOnQueue: networkQueue)
        let event = Event(guid: "", timestamp: Date(), type: "realTime", eventProtoData: Data())
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: networkQueue)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAliveService = DefaultKeepAliveService(with: schedulerQueueMock, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: networkQueue, persistence: persistence, keepAliveService: keepAliveService)
        let networkBuilder = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: networkQueue)
        //when
        let sut = DefaultEventBatchCreator(with: networkBuilder, performOnQueue: schedulerQueueMock)
        
        //then
        networkQueue.async {
            XCTAssertTrue(sut.forward(with: [event]))
        }
    }
    
    func test_whenNotReachableMockService_shouldReturnFalse() {
        //given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        
        let event = Event(guid: "", timestamp: Date(), type: "realTime", eventProtoData: Data())
        let deviceStatus = DefaultDeviceStatus(performOnQueue: networkQueue)
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: networkQueue)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let keepAliveService = DefaultKeepAliveService(with: schedulerQueueMock, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: false), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: networkQueue, persistence: persistence, keepAliveService: keepAliveService)
        let networkBuilder = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: networkQueue)
        //when
        let sut = DefaultEventBatchCreator(with: networkBuilder, performOnQueue: schedulerQueueMock)
        
        //then
        networkQueue.async {
            XCTAssertFalse(sut.forward(with: [event]))
        }
    }
}
