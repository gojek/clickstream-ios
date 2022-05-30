//
//  EventProcessorTest.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 24/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import SwiftProtobuf

class EventProcessorTest: XCTestCase {

    private let processorQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.processor", qos: .utility)
    private var config: NetworkConfigurations!
    private var networkService: DefaultNetworkService<SocketHandlerMockSuccess>!
    private var retryMech: DefaultRetryMechanism!
    private var networkBuilder: DefaultNetworkBuilder!
    private var prioritiesMock: [Priority]!
    private var eventBatchCreator: DefaultEventBatchCreator!
    private var schedulerServiceMock: DefaultSchedulerService!
    private var appStateNotifierMock: AppStateNotifierMock!
    private var defaultEventBatchProcessor: DefaultEventBatchProcessor!
    private var eventWarehouser: DefaultEventWarehouser!
    private var persistence: DefaultDatabaseDAO<EventRequest>!
    private var eventPersistence: DefaultDatabaseDAO<Event>!
    private var keepAliveService: DefaultKeepAliveService!
    private let dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network", qos: .utility, attributes: .concurrent)
    private let database = try! DefaultDatabase(qos: .WAL)
    private let batchSizeRegulator = BatchSizeRegulatorMock()
    
    override func setUp() {
        //given
        /// Network builder
        config = NetworkConfigurations(baseURL: URL(string: "ws://mock.clickstream.com/events")!)
        networkService = DefaultNetworkService<SocketHandlerMockSuccess>(with: config, performOnQueue: .main)
        persistence = DefaultDatabaseDAO<EventRequest>(database: database, performOnQueue: dbQueueMock)
        eventPersistence = DefaultDatabaseDAO<Event>(database: database, performOnQueue: dbQueueMock)

        keepAliveService = DefaultKeepAliveService(with: processorQueueMock, duration: 2, reachability: NetworkReachabilityMock(isReachable: true))

        retryMech = DefaultRetryMechanism(networkService: networkService, reachability: NetworkReachabilityMock(isReachable: true), deviceStatus: DefaultDeviceStatus(performOnQueue: processorQueueMock), appStateNotifier: AppStateNotifierMock(state: .didBecomeActive), performOnQueue: processorQueueMock, persistence: persistence, keepAliveService: keepAliveService)
        networkBuilder = DefaultNetworkBuilder(networkConfigs: config, retryMech: retryMech, performOnQueue: processorQueueMock)
        
        /// Event Splitter
        prioritiesMock = [Priority(priority: 0, identifier: "realTime", maxBatchSize: 50000.0, maxTimeBetweenTwoBatches: 1)]
        eventBatchCreator = DefaultEventBatchCreator(with: networkBuilder, performOnQueue: processorQueueMock)
        schedulerServiceMock = DefaultSchedulerService(with: prioritiesMock, performOnQueue: processorQueueMock)
        appStateNotifierMock = AppStateNotifierMock(state: .didBecomeActive)
        defaultEventBatchProcessor = DefaultEventBatchProcessor(with: eventBatchCreator, schedulerService: schedulerServiceMock, appStateNotifier: appStateNotifierMock, batchSizeRegulator: batchSizeRegulator, persistence: eventPersistence)
        eventWarehouser = DefaultEventWarehouser(with: defaultEventBatchProcessor, performOnQueue: processorQueueMock, persistence: eventPersistence, batchSizeRegulator: batchSizeRegulator)
    }

    override func tearDown() {
        config = nil
        networkService = nil
        retryMech = nil
        networkBuilder = nil
        prioritiesMock = nil
        eventBatchCreator = nil
        schedulerServiceMock = nil
        eventPersistence.deleteAll()
        appStateNotifierMock = nil
        defaultEventBatchProcessor = nil
        eventWarehouser = nil
    }
}
