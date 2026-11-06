//
//  EventVisualizerTestFixtures.swift
//  ClickstreamTests
//
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import Foundation

/// The SDK leaves `CollectionMapper` conformance to the host app's contracts, so the
/// tests conform an in-module protobuf message that has a top-level `eventName` field.
extension Gojek_Clickstream_Internal_Health: CollectionMapper { }

enum EventVisualizerTestFixtures {

    static func makeEvent(name: String,
                          numberOfEvents: Int64 = 0,
                          state: EventState = .received) -> EventData {
        var message = Gojek_Clickstream_Internal_Health()
        message.eventName = name
        message.numberOfEvents = numberOfEvents
        return EventData(msg: message, state: state)
    }

    static func makeDefaults(file: StaticString = #file, line: UInt = #line) -> UserDefaults {
        let suiteName = "EventVisualizerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
