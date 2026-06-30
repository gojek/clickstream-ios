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

        let eventName = eventName(from: message) ?? ""
        let eventGuid = eventGuid(from: message)
        let timestamp = extractTimestampString(in: message) ?? ""

        guard !eventName.isEmpty || !timestamp.isEmpty || eventGuid != nil else {
            return nil
        }

        return EventDisplaySummary(eventName: eventName, timestamp: timestamp, eventGuid: eventGuid)
    }

    static func eventGuid(from message: Any) -> String? {
        guard message is CollectionMapper else { return nil }
        // Targeted shallow scan: navigate _StorageClass → meta → eventGuid.
        // At most 4 Mirror reflections regardless of how many fields the event has.
        // Eliminates the full recursive Mirror walk and the asDictionary allocation.
        if let guid = shallowEventGuid(in: message) {
            return guid
        }

        // Last-resort fallback for non-standard schemas (events without a meta field,
        // or with a differently-named GUID field).
        return extractFirstString(in: message, matching: eventGuidLabels)
            ?? dictionaryString(from: message, keys: ["eventGuid", "guid", "storage.meta.storage.eventGuid"])
    }

    /// Walks at most 4 Mirror levels to find `meta.eventGuid` without doing a full
    /// recursive reflection or building an `asDictionary` snapshot.
    ///
    /// Handles two SwiftProtobuf storage layouts:
    /// - Simple structs: fields are direct children of the message mirror.
    /// - Complex structs: fields live on a `_StorageClass` child (`_storage`).
    private static func shallowEventGuid(in message: Any) -> String? {
        let messageMirror = Mirror(reflecting: message)

        for child in messageMirror.children {
            // Layout A — meta is a direct child of the message struct.
            if child.label == "meta" || child.label == "_meta" {
                if let guid = extractGuidFromMeta(child.value) { return guid }
            }

            // Layout B — SwiftProtobuf _StorageClass pattern:
            // message._storage._meta: EventMeta?
            if child.label == "_storage" {
                let storageMirror = Mirror(reflecting: child.value)
                for storageChild in storageMirror.children {
                    if storageChild.label == "meta" || storageChild.label == "_meta" {
                        if let guid = extractGuidFromMeta(storageChild.value) { return guid }
                    }
                }
            }
        }

        return nil
    }

    /// Given the raw value of a `meta` / `_meta` child (possibly Optional-wrapped),
    /// resolves it and returns the `eventGuid` string.
    ///
    /// - Does a shallow Mirror of the meta value itself, covering both
    ///   direct-field and `_StorageClass`-backed `EventMeta` layouts.
    private static func extractGuidFromMeta(_ value: Any) -> String? {
        guard let meta = resolvedValue(value) else { return nil }

        let metaMirror = Mirror(reflecting: meta)
        for child in metaMirror.children {
            if child.label == "eventGuid" || child.label == "_eventGuid" {
                if let str = resolvedValue(child.value) as? String, !str.isEmpty { return str }
            }
            // EventMeta may itself use _StorageClass.
            if child.label == "_storage" {
                let metaStorageMirror = Mirror(reflecting: child.value)
                for metaStorageChild in metaStorageMirror.children {
                    if metaStorageChild.label == "eventGuid" || metaStorageChild.label == "_eventGuid" {
                        if let str = resolvedValue(metaStorageChild.value) as? String, !str.isEmpty { return str }
                    }
                }
            }
        }

        return nil
    }

    static func eventName(from message: Any) -> String? {
        guard message is CollectionMapper else { return nil }

        // Targeted shallow scan: event_name is a direct field on every top-level
        // event struct, so it lives either as a direct child or inside _StorageClass.
        // At most 2 Mirror reflections regardless of how many fields the event has.
        if let name = shallowEventName(in: message) {
            return name
        }

        // Last-resort fallback for non-standard schemas.
        return extractFirstString(in: message, matching: eventNameLabels)
            ?? dictionaryString(from: message, keys: ["eventName", "storage.eventName"])
    }

    /// Walks at most 2 Mirror levels to find `eventName` without a full recursive
    /// reflection or `asDictionary` allocation.
    ///
    /// Handles two SwiftProtobuf storage layouts:
    /// - Simple structs: `eventName` / `_eventName` is a direct child of the message.
    /// - Complex structs: the field lives inside a `_StorageClass` child (`_storage`).
    private static func shallowEventName(in message: Any) -> String? {
        let messageMirror = Mirror(reflecting: message)

        for child in messageMirror.children {
            // Layout A — direct field on the message struct.
            if child.label == "eventName" || child.label == "_eventName" {
                if let str = resolvedValue(child.value) as? String, !str.isEmpty { return str }
            }

            // Layout B — SwiftProtobuf _StorageClass pattern:
            // message._storage._eventName: String
            if child.label == "_storage" {
                let storageMirror = Mirror(reflecting: child.value)
                for storageChild in storageMirror.children {
                    if storageChild.label == "eventName" || storageChild.label == "_eventName" {
                        if let str = resolvedValue(storageChild.value) as? String, !str.isEmpty { return str }
                    }
                }
            }
        }

        return nil
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
