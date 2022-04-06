//
//  SchedulerService.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 14/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol SchedulerServiceInputs {
    
    /// Call this method to start the timers based on the priorities.
    func start()
    
    /// Call this method to stop all the timers.
    func stop()
    
    /// Set this property to get the callbacks of the timer triggers.
    var subscriber: ((Priority)->())? { get set }
}

protocol SchedulerServiceOutputs { }

protocol SchedulerService: SchedulerServiceInputs, SchedulerServiceOutputs {}

/// A basic scheduler service which is used to provide a timed trigger to the subscriber.
/// DefaultSchedulerService deploys DispatchSourceTimer to initiate time based triggers.
final class DefaultSchedulerService: SchedulerService {
    
    private let performQueue: SerialQueue
    private let priorities: [Priority]
    lazy private(set) var timers = [String:DispatchSourceTimer]()

    var subscriber: ((Priority)->())?
    
    init(with priorities: [Priority],
         performOnQueue: SerialQueue) {
        self.priorities = priorities
        self.performQueue = performOnQueue
    }
    
    func start() {
        stop()
        start(with: priorities)
    }
    
    private func start(with priorities: [Priority]) {
        for priority in priorities {
            if let timer = makeTimer(with: priority) {
                timers[priority.identifier] = timer
            }
        }
    }
    
    private func makeTimer(with priority: Priority) -> DispatchSourceTimer? {
        guard let timeInterval = priority.maxTimeBetweenTwoBatches else { return nil }  // Schedule only those which have are time based.
        let timer: DispatchSourceTimer = DispatchSource.makeTimerSource(flags: .strict, queue: performQueue)
        timer.schedule(deadline: .now() + timeInterval, repeating: timeInterval)
        timer.setEventHandler(handler: { [weak self] in
            guard let checkedSelf = self else { return }
            checkedSelf.performQueue.async {
                checkedSelf.subscriber?(priority)
            }
        })
        timer.resume()
        return timer
    }
    
    func stop() {
        let timers = Array(self.timers.values)
        timers.forEach { $0.cancel() }
        self.timers.removeAll()
    }
    
    deinit {
        stop()
    }
}
