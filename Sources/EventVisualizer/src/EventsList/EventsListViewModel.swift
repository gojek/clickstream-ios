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

struct EventDisplayKeys {
    let eventTimeStamp: String
    let state: String
}

final class EventsListViewModel: EventsListViewModelInput {
    
    var messages: [Message] = []
    
    var selectedEventName: String = ""
    
    func cellViewModel(for indexPath: IndexPath) -> EventsListingTableViewCell.ViewModel {
        let values = getValues(index: indexPath)
        
        return EventsListingTableViewCell.ViewModel(
            name: values.eventTimeStamp,
            value: values.state
        )
    }
    
    func getValues(index: IndexPath) -> EventDisplayKeys {
        var eventTimeStamp = ""
        var state = ""
        if let message = messages[index.row] as? CollectionMapper {
            if let eventGuid = message.asDictionary[Constants.EventVisualizer.eventGuid] as? String {
                if let timestamp = message.asDictionary["_\(Constants.EventVisualizer.eventTimestamp)"] as? SwiftProtobuf.Google_Protobuf_Timestamp {
                    eventTimeStamp = "\(timestamp.date)"
                } else if let timestamp = message.asDictionary["\(Constants.EventVisualizer.eventTimestamp)"] as? SwiftProtobuf.Google_Protobuf_Timestamp {
                    eventTimeStamp = "\(timestamp.date)"
                }
                state = EventsHelper.shared.getState(of: eventGuid)
            } else if let eventGuid = message.asDictionary["storage.\(Constants.EventVisualizer.eventGuid)"] as? String,
                      let timestamp = message.asDictionary["storage.\(Constants.EventVisualizer.eventTimestamp)"] as? SwiftProtobuf.Google_Protobuf_Timestamp {
                eventTimeStamp = "\(timestamp.date)"
                state = EventsHelper.shared.getState(of: eventGuid)
            } else if let eventGuid = message.asDictionary["\(Constants.EventVisualizer.guid)"] as? String,
                      let timestamp = message.asDictionary["\(Constants.EventVisualizer.deviceTimestamp)"] as? SwiftProtobuf.Google_Protobuf_Timestamp {
                eventTimeStamp = "\(timestamp.date)"
                state = EventsHelper.shared.getState(of: eventGuid)
            }
        }
        return EventDisplayKeys(eventTimeStamp: eventTimeStamp, state: state)
    }
    
    var cellsCount: Int {
        return messages.count
    }
    
    func viewDidLoad(messages: [Message]?, selectedEventName: String?) {
        if let messages = messages, let selectedEventName = selectedEventName {
            /// Displaying the events making the most recent displayed on top
            self.messages = messages.reversed()
            self.selectedEventName = selectedEventName
        }
    }
    
    func didSelectRow(at indexPath: IndexPath) -> Message? {
        return messages[indexPath.row]
    }
}
