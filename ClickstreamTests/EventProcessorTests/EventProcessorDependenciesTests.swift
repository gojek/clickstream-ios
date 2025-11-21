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
        let config = DefaultNetworkConfiguration(request: URLRequest(url: URL(string: "ws://mock.clickstream.com")!))
        let prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1)]
        let rechability = NetworkReachabilityMock(isReachable: true)
        let appStateNotifier = AppStateNotifierMock(state: .didBecomeActive)

        let socketNetworkService = WebsocketNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: mockQueue)
        let courierNetworkService = CourierNetworkService<DefaultCourierHandler>(with: config, performOnQueue: mockQueue)

        let deviceStatus = DefaultDeviceStatus(performOnQueue: mockQueue)

        let socketPersistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        let courierPersistence = DefaultDatabaseDAO<CourierEventRequest>(database: database, performOnQueue: dbQueueMock)

        let socketEventPersistence = DefaultDatabaseDAO<Event>(database: database, performOnQueue: mockQueue)
        let courierEventPersistence = DefaultDatabaseDAO<CourierEvent>(database: database, performOnQueue: mockQueue)

        let keepAliveService = DefaultKeepAliveServiceWithSafeTimer(with: mockQueue, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))
        
        let networkOptions = ClickstreamNetworkOptions()

        let socketRetryMech = WebsocketRetryMechanism(
            networkService: socketNetworkService,
            reachability: rechability,
            deviceStatus: deviceStatus,
            appStateNotifier: appStateNotifier,
            performOnQueue: mockQueue,
            persistence: socketPersistence,
            keepAliveService: keepAliveService
        )
        
        let courierRetryMech = CourierRetryMechanism(
            networkOptions: networkOptions,
            networkService: courierNetworkService,
            reachability: rechability,
            deviceStatus: deviceStatus,
            appStateNotifier: appStateNotifier,
            performOnQueue: mockQueue,
            persistence: courierPersistence
        )
        
        let socketNetworkBuilder = WebsocketNetworkBuilder(networkConfigs: config,
                                                         retryMech: socketRetryMech,
                                                         performOnQueue: mockQueue)
        
        let courierNetworkBuilder = CourierNetworkBuilder(networkConfigs: config,
                                                          retryMech: courierRetryMech,
                                                          performOnQueue: mockQueue)

        let socketEventBatchCreator = DefaultEventBatchCreator(with: socketNetworkBuilder, performOnQueue: mockQueue)
        let courierEventBatchCreator = CourierEventBatchCreator(with: courierNetworkBuilder, performOnQueue: mockQueue)
        
        let schedulerServiceMock = DefaultSchedulerService(with: prioritiesMock, performOnQueue: mockQueue)
        
        let socketBatchProcessor = DefaultEventBatchProcessor(
            with: socketEventBatchCreator,
            schedulerService: schedulerServiceMock,
            appStateNotifier: appStateNotifier,
            batchSizeRegulator: BatchSizeRegulatorMock(),
            persistence: socketEventPersistence
        )
        
        let courierBatchProcessor = CourierEventBatchProcessor(
            with: courierEventBatchCreator,
            schedulerService: schedulerServiceMock,
            appStateNotifier: appStateNotifier,
            batchSizeRegulator: CourierBatchSizeRegulator(),
            persistence: courierEventPersistence
        )


        let socketEventWarehouser = DefaultEventWarehouser(with: socketBatchProcessor,
                                                           performOnQueue: mockQueue,
                                                           persistence: socketEventPersistence,
                                                           batchSizeRegulator: DefaultBatchSizeRegulator())

        let courieEventWarehouser = CourierEventWarehouser(with: courierBatchProcessor,
                                                           performOnQueue: mockQueue,
                                                           persistence: courierEventPersistence,
                                                           batchSizeRegulator: CourierBatchSizeRegulator(),
                                                           networkOptions: networkOptions)
                
        let eventProcessorDependencies = EventProcessorDependencies(socketEventWarehouser: socketEventWarehouser,
                                                                    courierEventWarehouser: courieEventWarehouser,
                                                                    networkOptions: ClickstreamNetworkOptions())

        let socketEventProcessor = eventProcessorDependencies.makeEventProcessor()
        let courierEventProcessor = eventProcessorDependencies.makeCourierEventProcessor()

        // then
        XCTAssertNotNil(socketEventProcessor)
        XCTAssertNotNil(courierEventProcessor)
    }
}
