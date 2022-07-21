//
//  HealthTracker.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 09/09/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class HealthTracker {
    
    private let daoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue,
                                       qos: .utility,
                                       attributes: .concurrent)
    private var queue: SerialQueue
    private var database: Database
    private let _persistence: DefaultDatabaseDAO<HealthAnalysisEvent>
    
    var persistence: DefaultDatabaseDAO<HealthAnalysisEvent> {
        get {
            return _persistence
        }
    }
    
    init(performOnQueue: SerialQueue,
         db: Database) {
        self.database = db
        self.queue = performOnQueue
        _persistence = DefaultDatabaseDAO<HealthAnalysisEvent>(database: database,
                                                                   performOnQueue: daoQueue)
    }
    
    func record(event: HealthAnalysisEvent) {
        queue.async {
            self._persistence.insert(event)
        }
    }
    
    /// Send health events to host/client app
    func sendHealthEventsToExternalParty() {
        queue.async {
            let trackeVia: TrackedVia = Tracker.healthTrackingConfigs.trackedVia == .both ? .both : .external
            
            var events: [HealthAnalysisEvent]!
            if Tracker.healthTrackingConfigs.trackedVia == .both {
                events = self._persistence.fetchAll()
            } else {
                events = self._persistence.deleteWhere(HealthAnalysisEvent.Columns.trackedVia,
                                                       value: trackeVia.rawValue)
            }
            
            guard !events.isEmpty else { return }
            
            let instantEvents = events.filter { $0.eventType.rawValue == TrackerConstant.EventType.instant.rawValue }
            for instantEvent in instantEvents {
                instantEvent.notify()
            }
            
            let aggregatedEvents = events.filter { $0.eventType == TrackerConstant.EventType.aggregate }
            
            var arrayOfAggreagatedEvents = [[HealthAnalysisEvent]]()
            
            for event in HealthEvents.allCases {
                let eventNameBasedAggregation = aggregatedEvents.filter { $0.eventName ==  event }
                if eventNameBasedAggregation.isEmpty {
                    continue
                }
                
                let groupingDictionary = Dictionary(grouping: eventNameBasedAggregation, by: { $0.reason })
                for (_, eventReasonBasedAggregation) in groupingDictionary {
                    if !eventReasonBasedAggregation.isEmpty {
                        arrayOfAggreagatedEvents.append(eventReasonBasedAggregation)
                    } else {
                        if !arrayOfAggreagatedEvents.contains(eventNameBasedAggregation) {
                            arrayOfAggreagatedEvents.append(eventNameBasedAggregation)
                        }
                    }
                }
            }
            
            arrayOfAggreagatedEvents.forEach { (eventArray) in
                if let eventName = eventArray.first?.eventName  {
                    let eventTimeStamps = eventArray.map { $0.timestamp }
                    let eventTimeStampString = "\(eventTimeStamps.joined(separator: ", "))"
                    
                    let eventBatchGUIDs: [String] = eventArray.compactMap { $0.eventBatchGUID }
                    
                    let eventGUIDs: [String] = eventArray.compactMap { $0.eventGUID }
                    
                    let healthAnalysisEventBatch = HealthAnalysisEventBatch(eventName: eventName, count: eventArray.count,
                                                                            timeStamps: eventTimeStampString,
                                                                            eventGUIDs: eventGUIDs,
                                                                            eventBatchGUIDs: eventBatchGUIDs,
                                                                            reason: eventArray.first?.reason)
                    healthAnalysisEventBatch.notify()
                }
            }
        }
    }
    
    @discardableResult
    func flushFunnelEvents() -> [HealthAnalysisEvent]? {
        let trackedVia: TrackedVia = Tracker.healthTrackingConfigs.trackedVia == .both ? .both : .internal
        if let doesTableExist = _persistence.doesTableExist(with: HealthAnalysisEvent.description), doesTableExist {
            return _persistence.deleteWhere(HealthAnalysisEvent.Columns.trackedVia,
                                            value: trackedVia.rawValue)
        }
        return nil
    }
}
