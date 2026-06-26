//
//  EventDisplayFieldReader.swift
//  EventVisualizer
//
//  Created by OpenAI.
//

import Foundation
import SwiftProtobuf

struct EventDisplayFields {
    let timestamp: String
    let eventGuid: String?
}

enum EventDisplayFieldReader {

    private static let eventGuidLabels: Set<String> = [
        "eventGuid",
        "guid",
        "eventGID"
    ]

    private static let timestampLabels: Set<String> = [
        "_eventTimestamp",
        "eventTimestamp",
        "deviceTimestamp"
    ]

    static func fields(from message: Any) -> EventDisplayFields {
        guard message is CollectionMapper else {
            return EventDisplayFields(timestamp: "", eventGuid: nil)
        }

        return extractFields(in: message)
    }

    static func eventGuid(from message: Any) -> String? {
        guard message is CollectionMapper else { return nil }
        return extractFields(in: message).eventGuid
    }

    static func timestampString(from message: Any) -> String? {
        guard message is CollectionMapper else { return nil }
        return extractFields(in: message).timestamp
    }

    private static func extractFields(in value: Any) -> EventDisplayFields {
        var eventGuid: String?
        var timestamp: String?
        search(in: value, eventGuid: &eventGuid, timestamp: &timestamp)
        return EventDisplayFields(timestamp: timestamp ?? "", eventGuid: eventGuid)
    }

    private static func search(
        in value: Any,
        eventGuid: inout String?,
        timestamp: inout String?
    ) {
        if eventGuid != nil && timestamp != nil {
            return
        }

        let mirror = Mirror(reflecting: value)

        for child in mirror.children {
            guard let label = child.label else { continue }

            if eventGuid == nil,
               eventGuidLabels.contains(label),
               let string = resolvedString(from: child.value) {
                eventGuid = string
            }

            if timestamp == nil,
               timestampLabels.contains(label),
               let timestampString = timestampValueString(from: child.value) {
                timestamp = timestampString
            }

            if eventGuid != nil && timestamp != nil {
                return
            }

            search(in: child.value, eventGuid: &eventGuid, timestamp: &timestamp)

            if eventGuid != nil && timestamp != nil {
                return
            }
        }
    }

    private static func resolvedString(from value: Any) -> String? {
        guard let resolved = resolvedValue(value) else { return nil }
        return resolved as? String
    }

    private static func timestampValueString(from value: Any) -> String? {
        if let resolved = resolvedValue(value) {
            if let date = resolved as? Date {
                return "\(date)"
            }

            if let timestamp = resolved as? Google_Protobuf_Timestamp {
                return "\(timestamp.date)"
            }
        }

        let mirror = Mirror(reflecting: value)
        var seconds: Int64?
        var nanos: Int32?

        for child in mirror.children {
            guard let label = child.label else { continue }

            if label == "seconds", let resolvedSeconds = resolvedValue(child.value) as? Int64 {
                seconds = resolvedSeconds
            } else if label == "nanos", let resolvedNanos = resolvedValue(child.value) as? Int32 {
                nanos = resolvedNanos
            }
        }

        if let seconds, let nanos {
            return "\(Google_Protobuf_Timestamp(seconds: seconds, nanos: nanos).date)"
        }

        return nil
    }

    private static func resolvedValue(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)

        guard mirror.displayStyle == .optional else {
            return value
        }

        guard let child = mirror.children.first else {
            return nil
        }

        return resolvedValue(child.value)
    }
}
