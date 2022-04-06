//
//  Constants.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

public typealias JSONString = String

typealias QueueIdentifier = String
typealias CacheIdentifier = String
typealias SerialQueue = DispatchQueue

enum Constants {
    
    static let SocketConnectionNotification = NSNotification.Name(rawValue: "SocketConnectionNotification")
    
    // MARK: - Strings
    enum Strings {
        static var connectionError = "Connection"
        static var didConnect = "didConnect"
    }
    
    // MARK: - SDK Defaults
    enum Defaults {
        
        // MARK: - Coefficients
        static let coefficientOfConnectionRetries = 1.3
        
        // MARK: - Device battery level
        static let minDeviceBatteryLevel: Float = 10.0
    }
    
    enum QueueIdentifiers: QueueIdentifier {
        case network = "com.clickstream.network"
        case scheduler = "com.clickstream.schedule"
        case processor = "com.clickstream.processor"
        case warehouser = "com.clickstream.warehouser"
        case dao = "com.clickstream.dao"
        case connectableAccess = "com.clickstream.connectableAccess"
        case atomicAccess = "com.clickstream.atomicAccess"
    }
    
    enum CacheIdentifiers: CacheIdentifier {
        case retry = "com.clickstream.retryCache"
    }
    
    enum EventType: String, Codable {
        case instant = "instant"
        case realTime = "realTime"
        case standard = "standard"
        case internalEvent = "internalEvent"
    }
}
