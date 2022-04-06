//
//  EventBatchProcessor.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 14/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol EventBatchProcessorInputs {
    
    /**
        Call this to start the batch processor.
        This method triggers the schedulers and app state notifier so that the events can be triggered.
     */
    func start()
    
    /// Call this to start the batch processor and stop the tracking.
    func stop()
    
    /// Call this method to send an event directly i.e. meant for instant sending.
    /// - Parameter event: Event to be forwarded
    func sendInstantly(event: Event) -> Bool
}

protocol EventBatchProcessorOutputs { }

protocol EventBatchProcessor: EventBatchProcessorInputs, EventBatchProcessorOutputs { }

/// This is the brains of the Scheduler block. This block is responsible for scheduling the events through the EventBatchCreator.
final class DefaultEventBatchProcessor: EventBatchProcessor {
    
    private let eventBatchCreator: EventBatchCreator
    private var schedulerService: SchedulerService
    private let appStateNotifier: AppStateNotifierService
    private let batchSizeRegulator: BatchSizeRegulator
    private let persistence: DefaultDatabaseDAO<Event>
    
    init(with eventBatchCreator: EventBatchCreator,
         schedulerService: SchedulerService,
         appStateNotifier: AppStateNotifierService,
         batchSizeRegulator: BatchSizeRegulator,
         persistence: DefaultDatabaseDAO<Event>) {
        self.eventBatchCreator = eventBatchCreator
        self.schedulerService = schedulerService
        self.appStateNotifier = appStateNotifier
        self.batchSizeRegulator = batchSizeRegulator
        self.persistence = persistence
    }
    
    func start() {
        self.subscribeToSchedule()
        self.observeAppStateChanges()
    }
    
    /// Adding a subscription to the scheduler service.
    private func subscribeToSchedule() {
        self.startTimer()
        self.schedulerService.subscriber = { [weak self] (priority) in guard let checkedSelf = self else { return }
            if checkedSelf.eventBatchCreator.canForward {
                if let maxBatchSize = priority.maxBatchSize {
                    let numberOfEventsToBeFetched = checkedSelf.batchSizeRegulator.regulatedNumberOfItemsPerBatch(expectedBatchSize: maxBatchSize)
                    if let events = checkedSelf.persistence.deleteWhere(Event.Columns.type,
                                                                        value: priority.identifier,
                                                                        n: numberOfEventsToBeFetched),
                       !events.isEmpty {
                        checkedSelf.eventBatchCreator.forward(with: events)
                    }
                } else {
                    checkedSelf.flush(with: priority)
                }
            }
        }
    }
    
    /// Adding a subscription to the app state changes.
    private func observeAppStateChanges() {
        appStateNotifier.start { [weak self] (stateNotification) in guard let checkedSelf = self else { return }
            switch stateNotification {
            case .willTerminate, .didEnterBackground:
                checkedSelf.flushAll()
            case .willResignActive:
                checkedSelf.stopTimer()
            case .didBecomeActive:
                checkedSelf.startTimer()
            case .willEnterForeground:
                break
            }
        }
    }
    
    private func startTimer() {
        self.schedulerService.start()
    }
    
    private func stopTimer() {
        self.schedulerService.stop()
    }
    
    private func flush(with priority: Priority) {
        if eventBatchCreator.canForward,
            let events = persistence.deleteAll() {
            eventBatchCreator.forward(with:events)
        }
    }
    
    /// flushing events. If `flushOnBackground` flag is set then flush.
    private func flushAll() {
        
        if Clickstream.constraints.flushOnBackground {
            stopObservingNotifications()
            
            var shouldFlush = false
            if let events = persistence.fetchAll(),
               !events.isEmpty {
                shouldFlush = true
            }
            
            if shouldFlush == false {
                return
            }
            
            if !eventBatchCreator.canForward {
                NotificationCenter.default.addObserver(self,
                                               selector: #selector(respondToNotification(with:)),
                                               name: Constants.SocketConnectionNotification,
                                               object: nil)
                eventBatchCreator.requestForConnection()
            } else {
                var eventsToBeFlushed = [Event]()
                if let events = persistence.deleteAll(),
                   !events.isEmpty {
                    eventsToBeFlushed.append(contentsOf: events)
                }
                
                if !eventsToBeFlushed.isEmpty {
                    eventBatchCreator.forward(with: eventsToBeFlushed)
                }
            }
        }
    }
    
    func sendInstantly(event: Event) -> Bool {
        return self.eventBatchCreator.forward(with: [event])
    }
    
    private func stopObservingNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: Constants.SocketConnectionNotification,
                                                  object: nil)
    }
    
    @objc private func respondToNotification(with notification: NSNotification) {
        if let object = notification.object as? [String: Any],
           let isConnected = object[Constants.Strings.didConnect] as? Bool,
           isConnected == true {
            flushAll()
        }
    }
    
    deinit {
        stop()
    }
    
    func stop() {
        stopObservingNotifications()
        schedulerService.stop()
        appStateNotifier.stop()
        eventBatchCreator.stop()
    }
}
