//
//  ClickStreamHealthConfigurations.swift
//  ClickStream
//
//  Created by Abhijeet Mallick on 04/05/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation

public enum HealthVerbosityLevel {
    case critical
    case verbose
    case none
}

public struct ClickstreamHealthConfigurations {
    
    // Track CS SDK health from minimum app version
    private(set) var minimumTrackedVersion: String
    
    // Enable tracking for userId with following randomising remainder
    private(set) var randomisingUserIdRemainders: [Int32]?
    
    // Enable tracking for following platform like CleverTap, ClickStream etc.
    private(set) var trackedVia: TrackedVia
    
    private(set) var verbosityLevel: HealthVerbosityLevel?
    
    public init(minimumTrackedVersion: String,
                randomisingUserIdRemainders: [Int32]? = nil,
                verbosityLevel: HealthVerbosityLevel? = HealthVerbosityLevel.none,
                trackedVia: TrackedVia) {
        
        self.minimumTrackedVersion = minimumTrackedVersion
        self.randomisingUserIdRemainders = randomisingUserIdRemainders
        self.verbosityLevel = verbosityLevel
        self.trackedVia = trackedVia
    }
    
    static var logVerbose: Bool {
//        Clickstream.healthTrackingConfigs?.verbosityLevel?.lowercased() == "maximum"
        return false
    }
    
    /// Returns an instance of ClickStreamEventClassification by decoding the json string.
    /// - Parameter json: String that needs to be decoded.
//    static func getInstance(from json: String) -> ClickstreamHealthConfigurations? {
//        return JSONStringDecoder.decode(json: json, fallbackJson: Constants.Defaults.Configs.healthTrackingConfigurations)
//    }
    
    func debugMode(userID: Int32, currentAppVersion: String) -> Bool {
        if minimumTrackedVersion.compare(currentAppVersion, options: .numeric) == .orderedAscending {
            print("currentAppVersion is newer")
            
            if let randomisingUserIdRemainders = self.randomisingUserIdRemainders {
                let randomisingUserIDRemainder = userID % 10
                return randomisingUserIdRemainders.contains(randomisingUserIDRemainder)
            }
            return true
        }
        return false
    }
    
    
    
    // Checks whether third party health tracking is supported or not
//    func isThirdPartySupported() -> Bool {
//        return self.trackedVia.contains(TrackedVia.external)
//    }
//    
//    // Checks whether CleverTap is supported or not
//    func isCSSupprted() -> Bool {
//        return self.trackedVia.contains(TrackedVia.internal)
//    }
}
