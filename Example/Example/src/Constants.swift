//
//  Constants.swift
//  Example
//
//  Created by Rishav Gupta on 14/04/23.
//  Copyright © 2023 Gojek. All rights reserved.
//

import Foundation

struct Constants {
    static var configurations = """
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
    
    /// Email and click count used for ETE Test Suite
    static var email = ""
    static var clickCount = 10
    
    static func authToken() -> String {
        let token = getContentsOfFile(name: "accessToken", type: "txt").replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil).replacingOccurrences(of: "\n", with: "", options: NSString.CompareOptions.literal, range: nil)
        return token
    }
    
    private static func getContentsOfFile(name: String, type: String) -> String {
        if let filepath = Bundle.main.path(forResource: name, ofType: type) {
            do {
                let contents = try String(contentsOfFile: filepath)
                return contents
            } catch {
                return ""
            }
        } else {
            return ""
        }
    }
    
    static func testConfigs() -> [String: Any]? {
        let config = getContentsOfFile(name: "testConfigs", type: "txt").replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\n", with: "", options: NSString.CompareOptions.literal, range: nil)
        return convertToDictionary(text: config)
    }
    
    static func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
