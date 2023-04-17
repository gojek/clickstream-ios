//
//  ClickStreamHealthConfigurations.swift
//  ClickStream
//
//  Created by Abhijeet Mallick on 04/05/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation

public struct ClickstreamHealthConfigurations: Decodable {
    
    /// Track CS SDK health from minimum app version
    private(set) var minimumTrackedVersion: String
    
    /// Enable tracking for userId with following randomising remainder
    private(set) var randomisingUserIdRemainders: [Int32]?
    
    /// Enable tracking for following platform like CleverTap, ClickStream etc.
    private(set) var trackedVia: TrackedVia
    
    /// Proto message name or any other string that will be used to distinguish drop rate health event.
    /// If you want to use a proto message name the you can directly call like this:- User.protoMessageName or CardEvent.protoMessageName
    private(set) var dropRateEventName: String
    
    var verbosityLevel: String?
    
    static var logVerbose: Bool {
        Clickstream.healthTrackingConfigs?.verbosityLevel?.lowercased() == "maximum"
    }
    
    /// Returns an instance of ClickStreamEventClassification by decoding the json string.
    /// - Parameter json: String that needs to be decoded.
    static func getInstance(from json: String) -> ClickstreamHealthConfigurations? {
        return JSONStringDecoder.decode(json: json, fallbackJson: Constants.Defaults.Configs.healthTrackingConfigurations)
    }
    
    public init(minimumTrackedVersion: String,
                randomisingUserIdRemainders: [Int32]? = nil,
                trackedVia: TrackedVia,
                dropRateEventName: String? = nil) {
        
        self.minimumTrackedVersion = minimumTrackedVersion
        self.randomisingUserIdRemainders = randomisingUserIdRemainders
        self.trackedVia = trackedVia
        self.dropRateEventName = dropRateEventName ?? ""
    }
    
    func debugMode(userID: Int32, currentAppVersion: String) -> Bool {
        if minimumTrackedVersion.compare(currentAppVersion, options: .numeric) == .orderedAscending {
            print("currentAppVersion is newer", .verbose)
            
            if let randomisingUserIdRemainders = self.randomisingUserIdRemainders {
                let randomisingUserIDRemainder = userID % 10
                return randomisingUserIdRemainders.contains(randomisingUserIDRemainder)
            }
            return true
        }
        return false
    }
}
