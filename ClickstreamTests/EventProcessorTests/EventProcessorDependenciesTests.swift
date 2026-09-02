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
    
    func testMakeCourierEventProcessor() {
        // given
        let config = DefaultNetworkConfiguration(request: URLRequest(url: URL(string: "https://mock.clickstream.com")!))
        let prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1)]
        let rechability = NetworkReachabilityMock(isReachable: true)
        let appStateNotifier = AppStateNotifierMock(state: .didBecomeActive)

        let courierNetworkService = CourierNetworkService<DefaultCourierHandler>(with: config, performOnQueue: mockQueue)
        let courierPersistence = DefaultDatabaseDAO<CourierEventRequest>(database: database, performOnQueue: dbQueueMock)
        let courierEventPersistence = DefaultDatabaseDAO<CourierEvent>(database: database, performOnQueue: mockQueue)
        
        let networkOptions = ClickstreamNetworkOptions()

        let courierRetryMech = CourierRetryMechanism(
            networkOptions: networkOptions,
            networkService: courierNetworkService,
            reachability: rechability,
            appStateNotifier: appStateNotifier,
            performOnQueue: mockQueue,
            persistence: courierPersistence
        )
        
        let courierNetworkBuilder = CourierNetworkBuilder(networkConfigs: config,
                                                          retryMech: courierRetryMech,
                                                          retryMechV2: nil,
                                                          performOnQueue: mockQueue)

        let courierEventBatchCreator = CourierEventBatchCreator(with: courierNetworkBuilder, performOnQueue: mockQueue, healthTrackingConfig: .init())
        
        let schedulerServiceMock = CourierSchedulerService(with: prioritiesMock, performOnQueue: mockQueue)
        
        let courierBatchProcessor = CourierEventBatchProcessor(
            with: courierEventBatchCreator,
            schedulerService: schedulerServiceMock,
            appStateNotifier: appStateNotifier,
            batchSizeRegulator: CourierBatchSizeRegulator(),
            persistence: courierEventPersistence
        )

        let courieEventWarehouser = CourierEventWarehouser(with: courierBatchProcessor,
                                                           performOnQueue: mockQueue,
                                                           persistence: courierEventPersistence,
                                                           batchSizeRegulator: CourierBatchSizeRegulator(),
                                                           networkOptions: networkOptions)
                
        let eventProcessorDependencies = EventProcessorDependencies(courierEventWarehouser: courieEventWarehouser,
                                                                    networkOptions: ClickstreamNetworkOptions())

        let courierEventProcessor = eventProcessorDependencies.makeCourierEventProcessor()

        // then
        XCTAssertNotNil(courierEventProcessor)
    }
}
