//
//  EventsListViewModel.swift
//  SettingsKit
//
//  Created by Rishav Gupta on 14/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import Foundation
import SwiftProtobuf
import UIKit

protocol EventsListViewModelInput: AnyObject {
    var cellsCount: Int { get }

    func viewDidLoad(
        messages: [Message]?,
        selectedEventName: String?,
        progress: @escaping (_ processedCount: Int, _ totalCount: Int) -> Void,
        completion: @escaping () -> Void
    )

    func cellViewModel(for indexPath: IndexPath) -> EventsListingTableViewCell.ViewModel

    func didSelectRow(at indexPath: IndexPath) -> Message?
}

struct EventDisplayKeys {
    let eventTimeStamp: String
    let state: String
}

final class EventsListViewModel: EventsListViewModelInput {

    private var messages: [Message] = []
    private var selectedEventName: String = ""
    private var cellViewModels: [EventsListingTableViewCell.ViewModel] = []

    private let processingQueue = DispatchQueue(label: "com.clickstream.eventvisualizer.eventslist.processing", qos: .userInitiated)

    var cellsCount: Int {
        return cellViewModels.count
    }

    func viewDidLoad(
        messages: [Message]?,
        selectedEventName: String?,
        progress: @escaping (_ processedCount: Int, _ totalCount: Int) -> Void,
        completion: @escaping () -> Void
    ) {
        guard let messages = messages else {
            self.messages = []
            self.selectedEventName = selectedEventName ?? ""
            self.cellViewModels = []
            progress(0, 0)
            completion()
            return
        }

        self.messages = Array(messages.reversed())
        self.selectedEventName = selectedEventName ?? ""

        let totalCount = self.messages.count
        DispatchQueue.main.async {
            progress(0, totalCount)
        }

        processingQueue.async { [weak self] in
            guard let self = self else { return }

            var renderedCells: [EventsListingTableViewCell.ViewModel] = []
            renderedCells.reserveCapacity(totalCount)

            for (index, message) in self.messages.enumerated() {
                renderedCells.append(self.makeViewModel(from: message))
                DispatchQueue.main.async {
                    progress(index + 1, totalCount)
                }
            }

            DispatchQueue.main.async {
                self.cellViewModels = renderedCells
                completion()
            }
        }
    }

    func cellViewModel(for indexPath: IndexPath) -> EventsListingTableViewCell.ViewModel {
        return cellViewModels[indexPath.row]
    }

    func didSelectRow(at indexPath: IndexPath) -> Message? {
        return messages[indexPath.row]
    }

    private func makeViewModel(from message: Message) -> EventsListingTableViewCell.ViewModel {
        let values = getValues(from: message)

        return EventsListingTableViewCell.ViewModel(
            name: values.eventTimeStamp,
            value: values.state
        )
    }

    private func getValues(from message: Message) -> EventDisplayKeys {
        var eventTimeStamp = ""
        var state = ""

        if let message = message as? CollectionMapper {
            if let eventGuid = message.asDictionary[Constants.EventVisualizer.eventGuid] as? String {
                if let timestamp = message.asDictionary["_\(Constants.EventVisualizer.eventTimestamp)"] as? Date {
                    eventTimeStamp = "\(timestamp)"
                } else if let timestamp = message.asDictionary["\(Constants.EventVisualizer.eventTimestamp)"] as? Date {
                    eventTimeStamp = "\(timestamp)"
                }
                state = EventsHelper.shared.getState(of: eventGuid)
            } else if let eventGuid = message.asDictionary["storage.\(Constants.EventVisualizer.eventGuid)"] as? String,
                      let timestamp = message.asDictionary["storage.\(Constants.EventVisualizer.eventTimestamp)"] as? Date {
                eventTimeStamp = "\(timestamp)"
                state = EventsHelper.shared.getState(of: eventGuid)
            } else if let eventGuid = message.asDictionary["\(Constants.EventVisualizer.guid)"] as? String,
                      let timestamp = message.asDictionary["\(Constants.EventVisualizer.deviceTimestamp)"] as? Date {
                eventTimeStamp = "\(timestamp)"
                state = EventsHelper.shared.getState(of: eventGuid)
            } else if let eventGuid = message.asDictionary["storage.meta.storage.\(Constants.EventVisualizer.eventGID)"] as? String,
                      let timestamp = message.asDictionary["storage.\(Constants.EventVisualizer.eventTimestamp)"] as? SwiftProtobuf.Google_Protobuf_Timestamp {
                eventTimeStamp = "\(timestamp.date)"
                state = EventsHelper.shared.getState(of: eventGuid)
            } else if let eventGuid = message.asDictionary["storage.meta.storage.\(Constants.EventVisualizer.eventGID)"] as? String {
                if let timestamp = message.asDictionary["storage.\(Constants.EventVisualizer.eventTimestamp)"] as? SwiftProtobuf.Google_Protobuf_Timestamp {
                    eventTimeStamp = "\(timestamp.date)"
                } else if let nanos = message.asDictionary["storage.eventTimestamp.nanos"] as? Int32,
                          let seconds = message.asDictionary["storage.eventTimestamp.seconds"] as? Int64 {
                    let timestamp = SwiftProtobuf.Google_Protobuf_Timestamp(seconds: seconds, nanos: nanos)
                    eventTimeStamp = "\(timestamp.date)"
                }
                state = EventsHelper.shared.getState(of: eventGuid)
            }
        }

        return EventDisplayKeys(eventTimeStamp: eventTimeStamp, state: state)
    }
}
