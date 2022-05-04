//
//  PerformanceEvent.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 08/09/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import Reachability
import GRDB

/// This struct is used for creating a single performance event
struct PerformanceEvent: Codable, Equatable, AnalysisEvent {
    private(set) var guid: String
    private(set) var eventName: ClickstreamDebugConstants.Performance.Events
    private(set) var eventGUID: String?
    private(set) var eventBatchGUID: String?
    private(set) var bucketType: ClickstreamDebugConstants.Performance.BucketType!
    private(set) var batchSize: Data?
    
    init?(eventName: ClickstreamDebugConstants.Performance.Events,
          guid: String? = nil,
          timestamp: Date? = nil,
          eventBatchSize: Data? = nil,
          eventBatchSentTimestamp: Date? = nil) {
        
        guard Tracker.debugMode  else {
            return nil
        }
        
        self.guid = UUID().uuidString
        self.eventName = eventName
        
        switch eventName {
        case .ClickstreamEventWaitTime:
            self.eventGUID = guid
            if let timestamp = timestamp {
                bucketType = self.getWaitTimeBucket(time: timestamp)
            }
        case .ClickstreamEventBatchLatency:
            self.eventBatchGUID = guid
            if let eventBatchSentTimestamp = eventBatchSentTimestamp {
                bucketType = self.getLatencyBucket(time: eventBatchSentTimestamp)
            }
        case .ClickstreamBatchSize:
            self.eventBatchGUID = guid
            self.batchSize = eventBatchSize
            bucketType = self.getBatchSizeBucket(batchSize: batchSize?.count ?? 0)
        case .ClickstreamEventBatchWaitTime:
            self.eventBatchGUID = guid
            if let timestamp = timestamp {
                bucketType = self.getWaitTimeBucket(time: timestamp, isEventBatch: true)
            }
        }
    }
    
    static func == (lhs: PerformanceEvent, rhs: PerformanceEvent) -> Bool {
        lhs.guid == rhs.guid
    }
    
    /// Used to get size  bucket type according to event batch
    /// - Parameter batchSize: Int
    /// - Returns: BucketType
    private func getBatchSizeBucket(batchSize: Int) -> ClickstreamDebugConstants.Performance.BucketType {
        let sizeInKB = batchSize/1000
        
        switch sizeInKB {
        case ..<10:
            return .LT_10KB
        case 10..<20:
            return .MT_10KB
        case 20..<50:
            return .MT_20KB
        case 50...:
            return .MT_50KB
        default:
            return .MT_50KB
        }
    }
    
    /// Used to get  latency bucket  type according to event batch
    /// - Parameter time: Date
    /// - Returns: BucketType
    // swiftlint:disable:next cyclomatic_complexity
    private func getLatencyBucket(time: Date) -> ClickstreamDebugConstants.Performance.BucketType {
        let elapsed = Int(Date().timeIntervalSince(time))
        let networkType = Reachability.getNetworkType()
        
        switch (elapsed, networkType) {
        case (..<1, NetworkType.wwan2g):
            return .LT_1sec_2G
        case (..<1, NetworkType.wwan3g):
            return .LT_1sec_3G
        case (..<1, NetworkType.wwan4g):
            return .LT_1sec_4G
        case (..<1, NetworkType.wifi):
            return .LT_1sec_WIFI
            
            
        case (..<3, NetworkType.wwan2g):
            return .MT_1sec_2G
        case (..<3, NetworkType.wwan3g):
            return .MT_1sec_3G
        case (..<3, NetworkType.wwan4g):
            return .MT_1sec_4G
        case (..<3, NetworkType.wifi):
            return .MT_1sec_WIFI
            
            
        case (3..., NetworkType.wwan2g):
            return .MT_3sec_2G
        case (3..., NetworkType.wwan3g):
            return .MT_3sec_3G
        case (3..., NetworkType.wwan4g):
            return .MT_3sec_4G
        case (3..., NetworkType.wifi):
            return .MT_3sec_WIFI
        default:
            return .MT_3sec_4G
        }
    }
    
    /// Used to get  Wait time bucket type according to event batch
    /// - Parameters:
    ///   - time: Date
    ///   - isEventBatch: true if it is a event batch
    /// - Returns: BucketType
    private func getWaitTimeBucket(time: Date, isEventBatch: Bool = false) -> ClickstreamDebugConstants.Performance.BucketType {
        let elapsed = Int(Date().timeIntervalSince(time))
        
        switch elapsed {
        case ..<5:
            return isEventBatch ? .LT_5sec_batch : .LT_5sec
        case ..<10:
            return isEventBatch ? .LT_10sec_batch : .LT_10sec
        case ..<20:
            return isEventBatch ? .MT_10sec_batch : .MT_10sec
        case 20...:
            return isEventBatch ? .MT_20sec_batch : .MT_20sec
        default:
            return isEventBatch ? .MT_20sec_batch : .MT_20sec
        }
    }
}

extension PerformanceEvent: DatabasePersistable {
    static var tableDefinition: (TableDefinition) -> Void {
        get {
            return { t in
                t.primaryKey(["guid"])
                t.column("guid")
                t.column("eventName", .integer)
                t.column("eventGUID", .text)
                t.column("eventBatchGUID", .text)
                t.column("bucketType", .integer)
                t.column("batchSize", .blob)
            }
        }
    }
    
    static var description: String {
        get {
            return "performanceEvent"
        }
    }
    
    static var codableCacheKey: String {
        return Constants.CacheIdentifiers.performanceAnalytics.rawValue
    }
    
    static var primaryKey: String {
        return "guid"
    }
    
    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]? {
        return nil
    }
}
