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

    private static let eventNameLabels: Set<String> = ["eventName"]
    private static let eventGuidLabels: Set<String> = ["eventGuid", "guid", "eventGID"]
    private static let timestampLabels: Set<String> = ["_eventTimestamp", "eventTimestamp", "deviceTimestamp"]

    static func fields(from message: Any) -> EventDisplayFields {
        guard let summary = summary(from: message) else {
            return EventDisplayFields(timestamp: "", eventGuid: nil)
        }

        return EventDisplayFields(timestamp: summary.timestamp, eventGuid: summary.eventGuid)
    }

    static func summary(from message: Any) -> EventDisplaySummary? {
        guard message is CollectionMapper else { return nil }

        let eventName = extractFirstString(in: message, matching: eventNameLabels)
            ?? dictionaryString(from: message, keys: ["eventName", "storage.eventName"])
            ?? ""
        let eventGuid = extractFirstString(in: message, matching: eventGuidLabels)
            ?? dictionaryString(from: message, keys: ["eventGuid", "guid", "storage.meta.storage.eventGuid"])
        let timestamp = extractTimestampString(in: message) ?? ""

        guard !eventName.isEmpty || !timestamp.isEmpty || eventGuid != nil else {
            return nil
        }

        return EventDisplaySummary(eventName: eventName, timestamp: timestamp, eventGuid: eventGuid)
    }

    static func eventGuid(from message: Any) -> String? {
        guard message is CollectionMapper else { return nil }
        return extractFirstString(in: message, matching: eventGuidLabels)
            ?? dictionaryString(from: message, keys: ["eventGuid", "guid", "storage.meta.storage.eventGuid"])
    }

    static func eventName(from message: Any) -> String? {
        guard message is CollectionMapper else { return nil }
        return extractFirstString(in: message, matching: eventNameLabels)
            ?? dictionaryString(from: message, keys: ["eventName", "storage.eventName"])
    }

    static func timestampString(from message: Any) -> String? {
        guard message is CollectionMapper else { return nil }
        return extractTimestampString(in: message)
    }

    private static func extractFirstString(in value: Any, matching labels: Set<String>) -> String? {
        let mirror = Mirror(reflecting: value)

        for child in mirror.children {
            guard let label = child.label else { continue }

            if labels.contains(label), let string = resolvedValue(child.value) as? String {
                return string
            }

            if let nestedValue = extractFirstString(in: child.value, matching: labels) {
                return nestedValue
            }
        }

        return nil
    }

    private static func extractTimestampString(in value: Any) -> String? {
        let mirror = Mirror(reflecting: value)

        for child in mirror.children {
            guard let label = child.label else { continue }

            if timestampLabels.contains(label), let timestampString = timestampValueString(from: child.value) {
                return timestampString
            }

            if let nestedValue = extractTimestampString(in: child.value) {
                return nestedValue
            }
        }

        return nil
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

    private static func dictionaryString(from message: Any, keys: [String]) -> String? {
        guard let collectionMapper = message as? CollectionMapper else { return nil }
        let dictionary = collectionMapper.asDictionary

        for key in keys {
            if let string = dictionary[key] as? String, !string.isEmpty {
                return string
            }
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
