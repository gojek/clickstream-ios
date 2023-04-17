//
//  MockConstants.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 02/07/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import Foundation

struct MockConstants {
    static let configurations =
        """
        {
          "maxConnectionRetries": 10,
          "maxConnectionRetryInterval": 30,
          "requestTimeOut": 20,
          "maxPingInterval": 15,
          "maxRetryIntervalPostPrematureDisconnection": 30,
          "maxRetriesPostPrematureDisconnection": 10,
          "flushOnBackground": true,
          "connectionTerminationTimerWaitTime": 2,
          "maxRequestAckTimeout": 6,
          "maxRetriesPerBatch": 20,
          "maxRetryCacheSize": 5000000,
          "connectionRetryDuration": 3,
          "flushOnAppLaunch": false,
          "minBatteryLevelPercent": 10.0,
          "priorities": [
            {
              "identifier": "realTime",
              "priority": 0,
              "maxBatchSize": 50000,
              "maxTimeBetweenTwoBatches": 10,
              "maxCacheSize": 5000000
            },
            {
              "identifier": "standard",
              "priority": 1,
              "maxCacheSize": 1000000
            }
          ]
        }
        """
    
    
    static let eventClassification =
        """
        {
          "eventTypes": [
              {
                "identifier": "ClickStreamTestRealtime",
                "eventNames": [
                    "gojek.clickstream.products.events.AdCardEvent"
                  ]
              },
              {
                "identifier": "ClickStreamTestStandard",
                "eventNames": [
                    "GoChat",
                    "GoPay"
                  ]
              }
            ]
        }
        """
    
    static let healthTrackingConfigurations = """
    {
        "minimumTrackedVersion":"4.18",
        "randomisingUserIdRemainders":[5,6],
        "destination":["CT"]
    }
    """
}
