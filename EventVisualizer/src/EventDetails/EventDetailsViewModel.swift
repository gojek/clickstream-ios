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
        if let eventGuid = selectedMessage?["guid"] {
            selectedMessage?["state"] = EventsHelper.shared.getState(of: "\(eventGuid)")
        }
        /// sorting the events that needs to be shown to the user
        displayedMessage = selectedMessage?.sorted { $0.0 < $1.0 }
        /// removing the events which does not have a value
        displayedMessage = displayedMessage?.filter { $0.1 as? String != "" && $0.1 as? String != nil }
        if let timestamp = selectedMessage?["_eventTimestamp"] as? SwiftProtobuf.Google_Protobuf_Timestamp {
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
