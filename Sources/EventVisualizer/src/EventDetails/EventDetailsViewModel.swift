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
    
    var selectedMessage: [String: Any]? { get set }
    
    var isSearchActive: Bool { get set }
        
    /// to store searched text
    var searchText: String { get set }
    
    func cellsCount() -> Int
        
    func viewDidLoad(message: Message?)
    
    func cellViewModel(for indexPath: IndexPath, with message: [(String, Any)]?) -> EventsListingTableViewCell.ViewModel
    
    func didSelectRow(at indexPath: IndexPath)
}

final class EventDetailsViewModel: EventDetailsModelInput {
    
    var selectedMessage: [String: Any]?
    var displayedMessage: [(String, Any)]?
    var searchedMessage: [(String, Any)]?
    
    var isSearchActive: Bool = false
    
    var searchText: String = ""
    
    private var searchResult: [String] = []
    
    func cellViewModel(for indexPath: IndexPath, with message: [(String, Any)]?) -> EventsListingTableViewCell.ViewModel {
        
        return EventsListingTableViewCell.ViewModel(
            name: message?[indexPath.row].0 ?? "invalid key",
            value: "\(message?[indexPath.row].1 ?? "invalid value")"
        )
    }
    
    func cellsCount() -> Int {
        if isSearchActive {
            guard let displayedMessage = displayedMessage else { return 0 }
            /// Filters messages which contain the key as the search Text where $0.0 refers to the first index of the tuple
            let filteredKeys = displayedMessage.filter { $0.0.lowercased().contains(searchText.lowercased()) }
            /// Storing the filteredKeys that would be used when the user clicks on the cell
            if searchText == "" {
                return displayedMessage.count
            } else {
                searchedMessage = filteredKeys
                return filteredKeys.count
            }
        } else {
            return displayedMessage?.count ?? 0
        }
    }
    
    func viewDidLoad(message: Message?) {
        if let message = message as? CollectionMapper {
            selectedMessage = message.asDictionary
        }
        if let eventGuid = selectedMessage?[Constants.EventVisualizer.eventGuid] as? String {
            selectedMessage?["state"] = EventsHelper.shared.getState(of: eventGuid)
        } else if let eventGuid = selectedMessage?[Constants.EventVisualizer.guid] as? String {
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
            (value as? Int64 != nil) ||
            (value as? Int != nil) ||
            (value as? Double != nil) ||
            (value is NSArray) ||
            /// checking if value is of enum type
            Mirror(reflecting: value).displayStyle?.equals(displayCase: .enum) ?? false ? true : false
        }
        if let timestamp = selectedMessage?["_\(Constants.EventVisualizer.eventTimestamp)"] as? SwiftProtobuf.Google_Protobuf_Timestamp {
            displayedMessage?.append(("eventTimestamp", "\(timestamp.date)"))
        }
    }
    
    ///  Action on selecting the row
    /// - Parameter indexPath: indexPath of that cell
    /// - Returns: returning tuple of (selected-event-name, message-array-of-events-with-that-event-name)
    func didSelectRow(at indexPath: IndexPath) {
        if isSearchActive {
            let model = cellViewModel(for: indexPath, with: searchedMessage)
            UIPasteboard.general.string = model.value
        } else {
            let model = cellViewModel(for: indexPath, with: displayedMessage)
            UIPasteboard.general.string = model.value
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
