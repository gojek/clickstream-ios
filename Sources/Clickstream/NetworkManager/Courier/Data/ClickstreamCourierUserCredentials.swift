//
//  CourierIdentifiers.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 14/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import UIKit

public protocol ClickstreamClientIdentifiers {
    var deviceIdentifier: String { get }
    var bundleIdentifier: String { get }
    var ownerType: String { get }
}

public protocol ClickstreamClientPostAuthIdentifiers: ClickstreamClientIdentifiers {
    var userIdentifier: String { get }
}

public protocol ClickstreamClientPreAuthIdentifiers: ClickstreamClientIdentifiers { }

public struct CourierPostAuthIdentifiers: ClickstreamClientPostAuthIdentifiers {

    public let userIdentifier: String
    public let deviceIdentifier: String
    public let bundleIdentifier: String
    public let ownerType: String

    public init(userIdentifier: String,
                deviceIdentifier: String = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
                bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "",
                ownerType: String) {

        self.userIdentifier = userIdentifier
        self.deviceIdentifier = deviceIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.ownerType = ownerType
    }
}

public struct CourierPreAuthIdentifiers: ClickstreamClientPreAuthIdentifiers {

    public let deviceIdentifier: String
    public let bundleIdentifier: String
    public let ownerType: String

    public init(deviceIdentifier: String = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
                bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "",
                ownerType: String) {

        self.deviceIdentifier = deviceIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.ownerType = ownerType
    }
}
