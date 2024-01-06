//
//  Constants.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

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
        static var eventGuid = "meta.eventGuid"
        static var guid = "guid"
        static var eventTimestamp = "eventTimestamp"
        static var deviceTimestamp = "deviceTimestamp"
    }
}
