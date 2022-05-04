//
//  HealthTracker.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 09/09/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

typealias HealthConstants = ClickstreamDebugConstants.Health

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
    
    func flushErrorEvents() {
        queue.async {
            if let events = self._persistence.deleteWhere(HealthAnalysisEvent.Columns.trackedVia,
                                                         value: ClickstreamDebugConstants.TrackedVia.cleverTap.rawValue),
                                                         !events.isEmpty {
                
                let instantEvents = events.filter { $0.eventType == ClickstreamDebugConstants.Health.EventType.instant }
                for instantEvent in instantEvents {
                    if let events = instantEvent.events {
                        let eventsArray = events.components(separatedBy: ", ")
                        let chunks = eventsArray.chunked(into: ClickstreamDebugConstants.propertyLengthConstraint)
                        for chunk in chunks {
                            let eventGUIDsString = "\(chunk.joined(separator: ", "))"
                            let healthEvent = HealthAnalysisEvent(eventName: instantEvent.eventName,
                                                                  events: eventGUIDsString,
                                                                  eventGUID: instantEvent.eventGUID,
                                                                  eventBatchGUID: instantEvent.eventBatchGUID,
                                                                  reason: instantEvent.reason)
                            healthEvent?.notify()
                        }
                    } else {
                        instantEvent.notify()
                    }
                }
                
                let aggregatedEvents = events.filter { $0.eventType == ClickstreamDebugConstants.Health.EventType.aggregate }
                
                var arrayOfAggreagatedEvents = [[HealthAnalysisEvent]]()
                
                for event in HealthConstants.Events.allCases {
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
                        let chunks = eventArray.chunked(into: ClickstreamDebugConstants.propertyLengthConstraint)
                        for chunk in chunks {
                            let eventTimeStamps = chunk.map { $0.timestamp }
                            let eventTimeStampString = "\(eventTimeStamps.joined(separator: ", "))"
                            
                            let eventBatchGUIDs: [String] = chunk.compactMap { $0.eventBatchGUID }
                            let eventBatchGUIDsString = "\(eventBatchGUIDs.joined(separator: ", "))"
                            
                            let eventGUIDs: [String] = chunk.compactMap { $0.eventGUID }
                            var eventGUIDsString: String = ""
                            if !eventGUIDs.isEmpty {
                                eventGUIDsString = "\(eventGUIDs.joined(separator: ", "))"
                            } else {
                                let eventsStrings = chunk.compactMap {$0.events}
                                for eventString in eventsStrings {
                                    eventGUIDsString += eventString
                                }
                            }
                            
                            let healthAnalysisEventBatch = HealthAnalysisEventBatch(eventName: eventName, count: chunk.count,
                                                                                    timeStamps: eventTimeStampString,
                                                                                    eventGUIDs: eventGUIDsString,
                                                                                    eventBatchGUIDs: eventBatchGUIDsString,
                                                                                    reason: chunk.first?.reason)
                            healthAnalysisEventBatch.notify()
                        }
                    }
                }
            }
        }        
    }
    
    @discardableResult
    func flushFunnelEvents() -> [HealthAnalysisEvent]? {
        if let doesTableExist = _persistence.doesTableExist(with: HealthAnalysisEvent.description), doesTableExist {
            return _persistence.deleteWhere(HealthAnalysisEvent.Columns.trackedVia,
                                            value: ClickstreamDebugConstants.TrackedVia.clickstream.rawValue)
        }
        return nil
    }
}