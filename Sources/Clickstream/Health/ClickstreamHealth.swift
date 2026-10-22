//
//  ClickstreamHealth.swift
//  Clickstream
//
//  Copyright © 2026 Gojek. All rights reserved.
//

import Foundation

/// A health event raised by the SDK. It is only created while health tracking is in debug mode and is
/// handed to the `ClickstreamHealthRecording` implementation, provided by the optional ClickstreamTracker module.
@_spi(ClickstreamInternal)
public struct ClickstreamHealthEvent {

    public let eventName: HealthEvents
    public let events: String?
    public let eventGUID: String?
    public let eventBatchGUID: String?
    public let reason: String?
    public let timeToConnection: String?
    public let eventCount: Int

    public init?(eventName: HealthEvents,
                 events: String? = nil,
                 eventGUID: String? = nil,
                 eventBatchGUID: String? = nil,
                 reason: String? = nil,
                 timeToConnection: String? = nil,
                 eventCount: Int = 0) {

        // Don't initialize if debugMode is off
        guard ClickstreamHealth.debugMode else {
            return nil
        }

        self.eventName = eventName
        self.events = events
        self.eventGUID = eventGUID
        self.eventBatchGUID = eventBatchGUID
        self.reason = reason
        self.timeToConnection = timeToConnection
        self.eventCount = eventCount
    }
}

/// A serialized health proto message, to be sent to Clickstream as an event.
@_spi(ClickstreamInternal)
public struct ClickstreamHealthPayload {

    public let guid: String
    public let messageBytes: Data
    public let messageName: String

    public init(guid: String, messageBytes: Data, messageName: String) {
        self.guid = guid
        self.messageBytes = messageBytes
        self.messageName = messageName
    }
}

/// Implemented by the optional ClickstreamTracker module to receive the SDK's health events.
@_spi(ClickstreamInternal)
public protocol ClickstreamHealthRecording: AnyObject {

    func record(event: ClickstreamHealthEvent?)

    /// Health events that are to be sent to Clickstream.
    func sendHealthEventsToInternalParty() -> [ClickstreamHealthPayload]?
}

/// Hook between the SDK and the optional ClickstreamTracker module.
/// Without the tracker module linked, `recorder` is nil and `debugMode` stays false, so health tracking is a no-op.
@_spi(ClickstreamInternal)
public enum ClickstreamHealth {

    /// Tells whether the debugMode is enabled or not.
    public static var debugMode: Bool = false

    /// Receives the health events.
    public static var recorder: ClickstreamHealthRecording?

    /// Set when the persistent store was found corrupt and recreated before the tracker was ready.
    /// Flushed as a `ClickstreamDBCorrupted` health event once the tracker is initialised.
    public static var pendingDatabaseCorruptionRecovery: Bool = false
}

extension ClickstreamHealth {

    /// Health events, in the form of Clickstream events, that are to be sent to Clickstream.
    static func internalEvents() -> [Event]? {
        recorder?.sendHealthEventsToInternalParty()?.compactMap {
            Event(guid: $0.guid,
                  messageBytes: $0.messageBytes,
                  messageName: $0.messageName,
                  type: TrackerConstant.HealthEventType)
        }
    }
}
