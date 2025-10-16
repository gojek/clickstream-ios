//
//  ClickstreamCourierUserCredentials.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 14/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import UIKit

public struct ClickstreamCourierUserCredentials {
    public let userIdentifier: String
    public let deviceIdentifier: String
    public let bundleIdentifier: String?
    public let extraIdentifier: String?
    public let authenticationHeaders: [String: String]?

    public init(userIdentifier: String,
                deviceIdentifier: String = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
                bundleIdentifier: String? = Bundle.main.bundleIdentifier,
                extraIdentifier: String? = nil,
                authenticationHeaders: [String: String]? = nil) {

        self.userIdentifier = userIdentifier
        self.deviceIdentifier = deviceIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.extraIdentifier = extraIdentifier
        self.authenticationHeaders = authenticationHeaders
    }
}
