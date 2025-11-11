//
//  CourierIdentifiers.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 14/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import UIKit

public protocol ClickstreamClientIdentifiers {
    var userIdentifier: String { get }
    var deviceIdentifier: String { get }
    var bundleIdentifier: String? { get }
    var extraIdentifier: String? { get }
    var authURLRequest: URLRequest { get }
}

public struct CourierIdentifiers: ClickstreamClientIdentifiers {

    public let userIdentifier: String
    public let deviceIdentifier: String
    public let bundleIdentifier: String?
    public let extraIdentifier: String?
    public let authURLRequest: URLRequest

    public init(userIdentifier: String,
                deviceIdentifier: String = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
                bundleIdentifier: String? = Bundle.main.bundleIdentifier,
                extraIdentifier: String? = nil,
                authURLRequest: URLRequest) {

        self.userIdentifier = userIdentifier
        self.deviceIdentifier = deviceIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.extraIdentifier = extraIdentifier
        self.authURLRequest = authURLRequest
    }
}
