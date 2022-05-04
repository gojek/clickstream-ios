//
//  PerformanceTracker.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 09/09/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class PerformanceTracker {
    
    private let daoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue,
                                       qos: .utility,
                                       attributes: .concurrent)
    private let queue: SerialQueue
    private let database: Database
    
    private(set) lazy var persistence: DefaultDatabaseDAO<PerformanceEvent> = {
        return DefaultDatabaseDAO<PerformanceEvent>(database: database,
                                                    performOnQueue: daoQueue)
    }()
    
    init(performOnQueue: SerialQueue,
         db: Database) {
        self.database = db
        self.queue = performOnQueue
    }
    
    func flushPerformanceAnalysis() {
        queue.async {
            guard let events = self.persistence.deleteAll() else { return }
            
            let groupingDictionary = Dictionary(grouping: events, by: { $0.bucketType })
            for (key, events) in groupingDictionary {
                if let key = key, !events.isEmpty {
                    let chunks = events.chunked(into: ClickstreamDebugConstants.propertyLengthConstraint)
                    for chunk in chunks {
                        let batch = PerformanceBatchEvent(bucketType: key, performanceEvents: chunk)
                        batch.notify()
                    }
                }
            }
        }
    }
    
    func record(event: PerformanceEvent) {
        queue.async {
            self.persistence.insert(event)
        }
    }
}
