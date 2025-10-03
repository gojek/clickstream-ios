//
//  ClickstreamNetworkOptions.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 03/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

public struct ClickstreamNetworkOptions {
    let isEnabled: Bool
    let options: Set<ClickstreamDispatcherOption>

    public init(isEnabled: Bool, options: Set<ClickstreamDispatcherOption>) {
        self.isEnabled = isEnabled
        self.options = options
    }
}

public typealias ClickstreamCourierEventIdentifier = String

public enum ClickstreamDispatcherOption: Hashable {
    case websocket
    case courier(events: Set<ClickstreamCourierEventIdentifier>)
}
