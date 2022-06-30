//
//  EventsListViewModel.swift
//  SettingsKit
//
//  Created by Rishav Gupta on 14/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol EventsListViewModelInput: AnyObject {
    
    var cellsCount: Int { get }
    
    var messages: [Message] { get set }
    
    var selectedEventName: String { get set }
        
    func viewDidLoad(messages: [Message]?, selectedEventName: String?)
    
    func cellViewModel(for indexPath: IndexPath) -> EventsListingTableViewCell.ViewModel
    
    func didSelectRow(at indexPath: IndexPath) -> Message?
}

final class EventsListViewModel: EventsListViewModelInput {
    
    var messages: [Message] = []
    
    var selectedEventName: String = ""
    
    func cellViewModel(for indexPath: IndexPath) -> EventsListingTableViewCell.ViewModel {
        
        var eventTimeStap = "Event at \(indexPath.row) index"
        var state = ""

        if let message = messages[indexPath.row] as? CollectionMapper {
            if let eventGuid = message.asDictionary["guid"] {
                state = EventsHelper.shared.getState(of: "\(eventGuid)")
            }
            if let timestamp = message.asDictionary["_deviceTimestamp"] as? SwiftProtobuf.Google_Protobuf_Timestamp {
                eventTimeStap = "\(timestamp.date)"
            }
        }
    
        return EventsListingTableViewCell.ViewModel(
            name: eventTimeStap,
            changedConfigsCount: state,
            availableConfigsCount: ""
        )
    }
    
    var cellsCount: Int {
        return messages.count
    }
    
    func viewDidLoad(messages: [Message]?, selectedEventName: String?) {
        if let messages = messages, let selectedEventName = selectedEventName {
            self.messages = messages
            self.selectedEventName = selectedEventName
        }
    }
    
    func didSelectRow(at indexPath: IndexPath) -> Message? {
        return messages[indexPath.row]
    }
}
