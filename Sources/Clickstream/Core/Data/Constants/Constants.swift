//
//  Constants.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

public typealias JSONString = String
public typealias AccessToken = String

typealias QueueIdentifier = String
typealias CacheIdentifier = String
typealias SerialQueue = DispatchQueue

enum Constants {
    
    static let SocketConnectionNotification = NSNotification.Name(rawValue: "SocketConnectionNotification")
    static let HealthEventType = "healthEvent"
    
    // MARK: - Strings
    enum Strings {
        static var connectionError = "Connection"
        static var deviceMake = "Apple"
        static var deviceOS = "iOS"
        static var didConnect = "didConnect"
        public static var status = "status"
        public static var success = "success"
        public static var failure = "failure"
        public static var networkType = "networkType"
    }
    
    // MARK: - SDK Defaults
    enum Defaults {
        
        // MARK: - Coefficients
        static let coefficientOfConnectionRetries = 1.3
        
        // MARK: - Default Configurations.
        enum Configs {
            static let configurations = """
               {
                 "maxConnectionRetries": 30,
                 "maxConnectionRetryInterval": 30,
                 "maxPingInterval": 15,
                 "maxRetryIntervalPostPrematureDisconnection": 30,
                 "maxRetriesPostPrematureDisconnection": 10,
                 "flushOnBackground": true,
                 "connectionTerminationTimerWaitTime": 8,
                 "maxRequestAckTimeout": 6,
                 "maxRetriesPerBatch": 20,
                 "maxRetryCacheSize": 5000000,
                 "connectionRetryDuration": 30,
                 "flushOnAppLaunch": false,
                 "minBatteryLevelPercent": 10.0,
                 "priorities": [
                   {
                     "identifier": "realTime",
                     "priority": 0,
                     "maxBatchSize": 50000,
                     "maxTimeBetweenTwoBatches": 10,
                     "maxCacheSize": 5000000
                   }
                 ]
               }
               """
            
            static let eventClassification = """
            {
              "eventTypes": [
                  {
                    "identifier": "realTime",
                    "eventNames": [
                        "gojek.clickstream.products.events.AdCardEvent"
                      ]
                  },
                    {
                      "identifier": "instant",
                      "eventNames": [
                        ""
                      ]
                    }
                ]
            }
            """
            
            static let healthTrackingConfigurations = """
            {
                "minimumTrackedVersion":"4.18",
                "randomisingUserIdRemainders":[5,6],
                "destination":["CT","CS"],
                "verbosityLevel": "maximum"
            }
            """
        }
    }
    
    enum QueueIdentifiers: QueueIdentifier {
        case network = "com.clickstream.network"
        case scheduler = "com.clickstream.schedule"
        case processor = "com.clickstream.processor"
        case warehouser = "com.clickstream.warehouser"
        case dao = "com.clickstream.dao"
        case connectableAccess = "com.clickstream.connectableAccess"
        case atomicAccess = "com.clickstream.atomicAccess"
        case tracker = "com.gojek.clickstream.tracker"
    }
    
    enum EventType: String, Codable {
        case instant = "instant"
        case realTime = "realTime"
        case standard = "standard"
        case internalEvent = "internalEvent"
    }
    
    enum EventVisualizer {
        static var guid = "guid"
        static var eventTimestamp = "deviceTimestamp"
    }
    
    enum CacheIdentifiers: CacheIdentifier {
        case retry = "com.gojek.clickstream.retryCache"
        case healthAnalytics = "com.gojek.clickstream.healthAnalyticsCache"
        case performanceAnalytics = "com.gojek.clickstream.performanceAnalyticsCache"
    }
}
