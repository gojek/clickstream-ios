//
//  EventPropertyReader.swift
//  EventVisualizer
//
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

/// Produces the flattened, sorted list of `(keyPath, value)` pairs shown on the
/// Event Details screen. Shared with the pinned-properties store so that a pinned
/// key path always matches what the details screen displays.
enum EventPropertyReader {

    static func entries(from message: Message?) -> [(String, Any)] {
        guard let mapper = message as? CollectionMapper else { return [] }
        var dictionary = mapper.asDictionary
        if let eventGuid = dictionary[Constants.EventVisualizer.eventGuid] as? String {
            dictionary["state"] = EventsHelper.shared.getState(of: eventGuid)
        } else if let eventGuid = dictionary[Constants.EventVisualizer.guid] as? String {
            dictionary["state"] = EventsHelper.shared.getState(of: eventGuid)
        }
        /// sorting the properties that needs to be shown to the user
        /// and removing the ones which do not have a displayable value
        return dictionary
            .sorted { $0.0 < $1.0 }
            .filter { isDisplayable($0.1) }
    }

    private static func isDisplayable(_ value: Any) -> Bool {
        return (value as? String != nil && value as? String != "") ||
            (value is Bool) ||
            (value as? Int32 != nil) ||
            (value as? Int64 != nil) ||
            (value as? Int != nil) ||
            (value as? UInt32 != nil) ||
            (value as? UInt64 != nil) ||
            (value as? Double != nil) ||
            (value as? Float != nil) ||
            (value is NSArray) ||
            /// checking if value is of enum type
            (Mirror(reflecting: value).displayStyle == .enum) ||
            /// checking if value is of Date type for showing SwiftProtobuf.Google_Protobuf_Timestamp.Date field's value in EV details screen
            (value is Date)
    }
}
