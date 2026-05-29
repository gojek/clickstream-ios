//
//  CourierEventCleanupManager.swift
//  Clickstream
//
//  Created by Rishab Habbu on 26/05/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

import UIKit

protocol EventCleanupProtocol {
    
    var persistence: DefaultDatabaseDAO<CourierEvent> { get }
    
    func schedule()
    
    func stop()
    
    func cleanUpExpiredEvents()
}

class CourierEventCleanupManager: EventCleanupProtocol {
    internal let persistence: DefaultDatabaseDAO<CourierEvent>
    
    var cleanupConfiguration: EventExpirationConfig
    
    init(cleanupConfiguration: EventExpirationConfig, persistence: DefaultDatabaseDAO<CourierEvent>) {
        self.cleanupConfiguration = cleanupConfiguration
        self.persistence = persistence
    }
    
    private let cleanupExpiredEventsSchedulerQueue = SerialQueue(label: Constants.QueueIdentifiers.scheduler.rawValue, qos: .utility)
    
    private lazy var expiredEventsCleanupScheduler : SchedulerService = {
        let cleanup_interval = cleanupConfiguration.ttlCleanupIntervalInMin
        let cleanupIntervalSeconds: TimeInterval = Double(cleanup_interval) * 60
        return EventCleanupScheduler(with: Priority(priority: 0, identifier: "cleanup", maxTimeBetweenTwoBatches: cleanupIntervalSeconds), performOnQueue: cleanupExpiredEventsSchedulerQueue)
    }()
    
    func schedule() {
        // TODO: Assign a concrete subscriber that uses cleanupIntervalSeconds
       expiredEventsCleanupScheduler.start()
    }
    
    func stop() {
        expiredEventsCleanupScheduler.stop()
    }
    
    func cleanUpExpiredEvents() {
        self.schedule()
        self.expiredEventsCleanupScheduler.subscriber = { [weak self] _ in
            guard let checkedSelf = self else { return }
            checkedSelf.persistence.deleteWhere(CourierEvent.Columns.ttl, lessThan: Date())
        }
    }
}

class DefaultEventCleanupManager: EventCleanupProtocol {
    
    internal let persistence: DefaultDatabaseDAO<CourierEvent>
    
    init(persistence: DefaultDatabaseDAO<CourierEvent>) {
        self.persistence = persistence
    }
    
    private let cleanupExpiredEventsSchedulerQueue = SerialQueue(label: Constants.QueueIdentifiers.scheduler.rawValue, qos: .utility)
    
    private lazy var expiredEventsCleanupScheduler : SchedulerService = {
        let cleanupIntervalSeconds: TimeInterval =  10
        return EventCleanupScheduler(with: Priority(priority: 0, identifier: "cleanup", maxTimeBetweenTwoBatches: cleanupIntervalSeconds), performOnQueue: cleanupExpiredEventsSchedulerQueue)
    }()
    
    func schedule() {
        expiredEventsCleanupScheduler.start()
    }
    
    func stop() {
        expiredEventsCleanupScheduler.stop()
    }
    
    func cleanUpExpiredEvents() {
        self.schedule()
        self.expiredEventsCleanupScheduler.subscriber = { [weak self] _ in
            guard let checkedSelf = self else { return }
            checkedSelf.persistence.deleteWhere(CourierEvent.Columns.ttl, lessThan: Date())
        }
    }
}


final class EventCleanupScheduler: SchedulerService {
    
    private let performQueue: SerialQueue
    private let priority: Priority
    private var timer: DispatchSourceTimer?

    var subscriber: ((Priority)->())?
    
    init(with priority: Priority,
         performOnQueue: SerialQueue) {
        self.priority = priority
        self.performQueue = performOnQueue
    }
    
    func start() {
        stop()
        self.timer = makeTimer()
    }
    
    func makeTimer() -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: performQueue)
        let interval = priority.maxTimeBetweenTwoBatches

        let safeInterval: TimeInterval = interval ?? 0

        timer.schedule(deadline: .now() + safeInterval, repeating: safeInterval)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.subscriber?(self.priority)
        }
        timer.resume()
        return timer
    }
    
    func stop() {
        if let t = timer {
            t.setEventHandler(handler: nil)
            t.cancel()
            timer = nil
        }
    }
    
}

