//
//  CSCommonProperties.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf
import UIKit

/**
 Common properties which need to be sent along every event being sent. Container for all the common properties to be tracked.
 - important: Need not be set every time, set once and the SDK will attach it to every event being sent to `Clickstream` for tracking.
 */
public struct CSCommonProperties {
    
    /// Holds the customer info (`CSCustomerInfo`)  for a given app session. Needs to be supplied by the client.
    private(set) var customer: CSCustomerInfo
    /// Holds the session info (`CSSessionInfo`)  for a given app session. Needs to be supplied by the client.
    private(set) var session: CSSessionInfo
    /// Holds the device info (`CSDeviceInfo`)  for a given app session. Does not need to be supplied by the client.
    private(set) var device: CSDeviceInfo = CSDeviceInfo()
    /// Holds the app info (`CSAppInfo`)  for a given app session. Needs to be supplied by the client.
    private(set) var app: CSAppInfo
    
    /// Public initialiser for `CSCommonProperties`
    /// - Parameters:
    ///   - customer: customer info to be added to every event.
    ///   - session: session info to be added to every event.
    ///   - app: app info to be added to every event.
    public init(customer: CSCustomerInfo,
                session: CSSessionInfo,
                app: CSAppInfo) {
        self.customer = customer
        self.session = session
        self.app = app
    }
}

/**
 Customer Info properties which need to be sent along every event being sent.
 - important: Need not be set every time, set once and the SDK will attach it to every event being sent to `Clickstream` for tracking.
 */
public struct CSCustomerInfo {
    
    /// Holds the country where the user signed up.
    private(set) var signedUpCountry: String
    /// Holds the user email.
    private(set) var email: String
    /// Holds the current country where the user is.
    private(set) var currentCountry: String
    /// Holds the unique id of the user.
    private(set) var identity: Int32
    
    /// Public initialiser for `CSCustomerInfo`
    /// - Parameters:
    ///   - signedUpCountry: country where the user signed up.
    ///   - email: user email.
    ///   - currentCountry: current country where the user is.
    ///   - identity: unique id of the user.
    public init(signedUpCountry: String,
                email: String,
                currentCountry: String,
                identity: Int32) {
        self.signedUpCountry = signedUpCountry
        self.email = email
        self.currentCountry = currentCountry
        self.identity = identity
    }
}

extension CSCustomerInfo: ProtoConvertible {
    var proto: Gojek_Clickstream_Internal_HealthMeta.Customer {
        let customerInfo = Gojek_Clickstream_Internal_HealthMeta.Customer.with {
            $0.signedUpCountry = signedUpCountry
            $0.currentCountry = currentCountry
            $0.email = email
            $0.identity = identity
        }
        return customerInfo
    }
}

/**
 Session Info properties which need to be sent along every event being sent.
 - important: Need not be set every time, set once and the SDK will attach it to every event being sent to `Clickstream` for tracking.
 */
public struct CSSessionInfo {
    
    /// Holds the session id for the given user session.
    var sessionId: String
    
    /// Public initialiser for `CSSessionInfo`
    /// - Parameter sessionId: session id for the given user session.
    public init(sessionId: String) {
        self.sessionId = sessionId
    }
}

extension CSSessionInfo: ProtoConvertible {
    var proto: Gojek_Clickstream_Internal_HealthMeta.Session {
        let sessionInfo = Gojek_Clickstream_Internal_HealthMeta.Session.with {
            $0.sessionID = sessionId
        }
        return sessionInfo
    }
}

/**
 Session Info properties which need to be sent along every event being sent.
 - important: Need not be set. Gets set internally.
 */
struct CSDeviceInfo {
    let operatingSystem = TrackerConstant.deviceOS
    let operatingSystemVersion = UIDevice.current.systemVersion
    let deviceMake = TrackerConstant.deviceMake
    let deviceModel = UIDevice.csModelName
}

extension CSDeviceInfo: ProtoConvertible {
    var proto: Gojek_Clickstream_Internal_HealthMeta.Device {
        return Gojek_Clickstream_Internal_HealthMeta.Device.with {
            $0.operatingSystem = TrackerConstant.deviceOS
            $0.operatingSystemVersion = UIDevice.current.systemVersion
            $0.deviceMake = TrackerConstant.deviceMake
            $0.deviceModel = UIDevice.csModelName
        }
    }
}

/**
 App Info properties which need to be sent along every event being sent. Holds the appVersion.
 - important: Need not be set every time, set once and the SDK will attach it to every event being sent to `Clickstream` for tracking.
 */
public struct CSAppInfo {
    
    /// Holds the version of the client app.
    private(set) var version: String
    
    /// Public initialiser for `CSAppInfo`
    /// - Parameter version: version of the client app.
    public init(version: String) {
        self.version = version
    }
}

extension CSAppInfo: ProtoConvertible {
    var proto: Gojek_Clickstream_Internal_HealthMeta.App {
        return Gojek_Clickstream_Internal_HealthMeta.App.with {
            $0.version = version
        }
    }
}
