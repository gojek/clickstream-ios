//
//  EventsPinnedPropertiesStore.swift
//  EventVisualizer
//
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

/// A property of a named event that the user pinned, e.g. `("Order Placed", "orderId")`.
public struct EventsPinnedProperty: Codable, Hashable {
    public let eventName: String
    public let keyPath: String

    public init(eventName: String, keyPath: String) {
        self.eventName = eventName
        self.keyPath = keyPath
    }
}

/// A pinned property together with its latest captured value.
public struct EventsPinnedValue: Equatable {
    public let pin: EventsPinnedProperty
    public let value: String
}

/// Persists pinned properties and resolves their latest values from `EventsHelper`.
/// Intended to be used from the main thread.
public final class EventsPinnedPropertiesStore {

    public static let shared = EventsPinnedPropertiesStore()

    /// Posted on the main thread whenever the set of pins changes.
    public static let didChangeNotification = Notification.Name("EventsPinnedPropertiesStoreDidChangeNotification")

    /// Shown when a pinned property has no captured value yet.
    public static let emptyValue = "-"

    private static let defaultsKey = "eventsVisualizerPinnedProperties"

    private let defaults: UserDefaults
    private let helper: EventsHelper

    public private(set) var pins: [EventsPinnedProperty]

    init(defaults: UserDefaults = .standard, helper: EventsHelper = .shared) {
        self.defaults = defaults
        self.helper = helper
        self.pins = Self.loadPins(from: defaults)
    }

    public func contains(_ pin: EventsPinnedProperty) -> Bool {
        return pins.contains(pin)
    }

    public func add(_ pin: EventsPinnedProperty) {
        guard !contains(pin) else { return }
        pins.append(pin)
        persistAndNotify()
    }

    public func remove(_ pin: EventsPinnedProperty) {
        guard contains(pin) else { return }
        pins.removeAll { $0 == pin }
        persistAndNotify()
    }

    public func removeAll() {
        guard !pins.isEmpty else { return }
        pins.removeAll()
        persistAndNotify()
    }

    /// Adds the pin if absent, removes it otherwise.
    public func toggle(_ pin: EventsPinnedProperty) {
        if contains(pin) {
            remove(pin)
        } else {
            add(pin)
        }
    }

    /// Latest value of every pin, in pin order.
    public func currentValues() -> [EventsPinnedValue] {
        guard !pins.isEmpty else { return [] }
        let latestEvents = helper.latestEvents(named: Set(pins.map(\.eventName)))
        var entriesByEvent: [String: [String: String]] = [:]
        return pins.map { pin in
            if entriesByEvent[pin.eventName] == nil {
                entriesByEvent[pin.eventName] = latestEvents[pin.eventName].map { event in
                    Dictionary(Self.entries(of: event).map { ($0.0, $0.1) }, uniquingKeysWith: { first, _ in first })
                } ?? [:]
            }
            return EventsPinnedValue(pin: pin, value: entriesByEvent[pin.eventName]?[pin.keyPath] ?? Self.emptyValue)
        }
    }

    /// Distinct, sorted names of the captured events.
    func capturedEventNames() -> [String] {
        return helper.capturedEventNames()
    }

    /// The most recently captured event with the given name.
    func latestEvent(named eventName: String) -> EventData? {
        return helper.latestEvents(named: [eventName])[eventName]
    }

    private func persistAndNotify() {
        if let data = try? JSONEncoder().encode(pins) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
        let post = { NotificationCenter.default.post(name: Self.didChangeNotification, object: self) }
        if Thread.isMainThread {
            post()
        } else {
            DispatchQueue.main.async(execute: post)
        }
    }

    private static func loadPins(from defaults: UserDefaults) -> [EventsPinnedProperty] {
        guard let data = defaults.data(forKey: defaultsKey),
              let pins = try? JSONDecoder().decode([EventsPinnedProperty].self, from: data) else { return [] }
        return pins
    }

    /// `(keyPath, displayValue)` pairs, identical to what the Event Details screen lists.
    private static func entries(of event: EventData) -> [(String, String)] {
        return EventPropertyReader.entries(from: event.msg).map { key, value in
            let text = "\(value)"
            return (key, text.isEmpty ? emptyValue : text)
        }
    }
}
