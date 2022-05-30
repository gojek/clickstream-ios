//
//  EventProcessorDependenciesTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 30/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class EventProcessorDependenciesTests: XCTestCase {

    private let database = try! DefaultDatabase(qos: .WAL)
    private let dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
    private let mockQueue = SerialQueue(label: "com.mock.gojek.clickstream.processor", qos: .utility)
    private let realTimeEvent = Event(guid: "", timestamp: Date(), type: "realTime", eventProtoData: Data())
    
    func testMakeEventProcessor() {
        // given
        let config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        let prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1)]
        
        let networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: mockQueue)
        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)
        let persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let eventPersistence = DefaultDatabaseDAO<Event>(database: database, performOnQueue: mockQueue)
        let keepAliveService = DefaultKeepAliveService(with: mockQueue, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        let retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: deviceStatus, appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: mockQueue, persistence: persistence, keepAliveService: keepAliveService)
        
        let networkBuilder: NetworkBuildable = DefaultNetworkBuilder.init(networkConfigs: config, retryMech: retryMech, performOnQueue: mockQueue)
        
        let eventBatchCreator = DefaultEventBatchCreator(with: networkBuilder, performOnQueue: mockQueue)
        
        let appStateNotifierMock = AppStateNotifierMock(state: .didBecomeActive)
        
        let schedulerServiceMock = DefaultSchedulerService(with: prioritiesMock, performOnQueue: mockQueue)
        
        let batchProcessor = DefaultEventBatchProcessor(with: eventBatchCreator, schedulerService: schedulerServiceMock, appStateNotifier: appStateNotifierMock, batchSizeRegulator: BatchSizeRegulatorMock(), persistence: eventPersistence)

        let eventWarehouser = DefaultEventWarehouser(with: batchProcessor, performOnQueue: mockQueue, persistence: eventPersistence, batchSizeRegulator: BatchSizeRegulatorMock())
        
                
        let eventProcessorDependencies = EventProcessorDependencies(with: eventWarehouser)
        let eventProcessor = eventProcessorDependencies.makeEventProcessor()
        
        // then
        XCTAssertNotNil(eventProcessor)
    }
}
