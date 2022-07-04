//
//  EventDetailsViewModel.swift
//  SettingsKit
//
//  Created by Rishav Gupta on 14/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol EventDetailsModelInput: AnyObject {
    
    var cellsCount: Int { get }
    
    var selectedMessage: [String: Any]? { get set }
        
    func viewDidLoad(message: Message?)
    
    func cellViewModel(for indexPath: IndexPath) -> EventsListingTableViewCell.ViewModel
}

final class EventDetailsViewModel: EventDetailsModelInput {
    
    var selectedMessage: [String: Any]?
    var displayedMessage: [(String, Any)]?
    
    func cellViewModel(for indexPath: IndexPath) -> EventsListingTableViewCell.ViewModel {
        
        return EventsListingTableViewCell.ViewModel(
            name: displayedMessage?[indexPath.row].0 ?? "invalid key",
            changedConfigsCount: "\(displayedMessage?[indexPath.row].1 ?? "invalid value")",
            availableConfigsCount: ""
        )
    }
    
    var cellsCount: Int {
        displayedMessage?.count ?? 0
    }
    
    func viewDidLoad(message: Message?) {
        if let message = message as? CollectionMapper {
            selectedMessage = message.asDictionary
        }
        if let eventGuid = selectedMessage?[Constants.EventVisualizer.guid] as? String {
            selectedMessage?["state"] = EventsHelper.shared.getState(of: eventGuid)
        }
        /// sorting the events that needs to be shown to the user
        displayedMessage = selectedMessage?.sorted { $0.0 < $1.0 }
        /// removing the events which does not have a value
        displayedMessage = displayedMessage?.filter {
            /// $0 provides a [String: Any] and $0.1 provides the value to the dictionary
            /// checking if value is not empty, then filter it out.
            let value = $0.1
            return (value as? String != nil && value as? String != "") ||
            (value is Bool) ||
            (value as? Int32 != nil) ||
            (value as? Int != nil) ||
            (value as? Double != nil) ||
            (value is NSArray) ||
            /// checking if value is of enum type
            Mirror(reflecting: value).displayStyle?.equals(displayCase: .enum) ?? false ? true : false
        }
        if let timestamp = selectedMessage?[Constants.EventVisualizer.eventTimestamp] as? SwiftProtobuf.Google_Protobuf_Timestamp {
            displayedMessage?.append(("eventTimestamp", "\(timestamp.date)"))
        }
    }
}

private extension Dictionary {
    subscript(ind: Int) -> (key: Key, value: Value) {
        get {
            return self[index(startIndex, offsetBy: ind)]
        }
    }
}

private extension Mirror.DisplayStyle {
    func equals(displayCase: Mirror.DisplayStyle) -> Bool {
        return self == displayCase
    }
}
