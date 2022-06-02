//
//  ClickStreamHealthConfigurations.swift
//  ClickStream
//
//  Created by Abhijeet Mallick on 04/05/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation

public struct ClickstreamHealthConfigurations {
    
    // Track CS SDK health from minimum app version
    private(set) var minimumTrackedVersion: String
    
    // Enable tracking for userId with following randomising remainder
    private(set) var randomisingUserIdRemainders: [Int32]?
    
    // Enable tracking for following platform like CleverTap, ClickStream etc.
    private(set) var trackedVia: TrackedVia
    
    /// Enable verbosity level of event properties
    private(set) var verbosityLevel: VerbosityLevel?
    
    public init(minimumTrackedVersion: String,
                randomisingUserIdRemainders: [Int32]? = nil,
                verbosityLevel: VerbosityLevel? = VerbosityLevel.minimum,
                trackedVia: TrackedVia) {
        
        self.minimumTrackedVersion = minimumTrackedVersion
        self.randomisingUserIdRemainders = randomisingUserIdRemainders
        self.verbosityLevel = verbosityLevel
        self.trackedVia = trackedVia
    }
    
    static var logVerbose: Bool {
        return Tracker.healthTrackingConfigs?.verbosityLevel == .maximum
    }
    
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
}
