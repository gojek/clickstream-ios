//
//  EventsListViewModel.swift
//  EventVisualizer
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

private struct EventListItem {
    let timestamp: String
    let state: String
}

final class EventsListViewModel: EventsListViewModelInput {

    private var messages: [Message] = []
    private var listItems: [EventListItem] = []

    private let processingQueue = DispatchQueue(label: "com.clickstream.eventvisualizer.eventslist.processing", qos: .userInitiated)

    var cellsCount: Int {
        return listItems.count
    }

    func viewDidLoad(
        messages: [Message]?,
        selectedEventName: String?,
        progress: @escaping (_ processedCount: Int, _ totalCount: Int) -> Void,
        completion: @escaping () -> Void
    ) {
        guard let messages = messages else {
            self.messages = []
            self.listItems = []
            progress(0, 0)
            completion()
            return
        }

        self.messages = Array(messages.reversed())

        let totalCount = self.messages.count
        let progressBatchSize = max(1, totalCount / 20)
        DispatchQueue.main.async {
            progress(0, totalCount)
        }

        processingQueue.async { [weak self] in
            guard let self = self else { return }

            var renderedItems: [EventListItem] = []
            renderedItems.reserveCapacity(totalCount)

            for (index, message) in self.messages.enumerated() {
                renderedItems.append(self.makeListItem(from: message))
                let processedCount = index + 1
                if processedCount % progressBatchSize == 0 || processedCount == totalCount {
                    DispatchQueue.main.async {
                        progress(processedCount, totalCount)
                    }
                }
            }

            DispatchQueue.main.async {
                self.listItems = renderedItems
                completion()
            }
        }
    }

    func cellViewModel(for indexPath: IndexPath) -> EventsListingTableViewCell.ViewModel {
        let item = listItems[indexPath.row]
        return EventsListingTableViewCell.ViewModel(name: item.timestamp, value: item.state)
    }

    func didSelectRow(at indexPath: IndexPath) -> Message? {
        return messages[indexPath.row]
    }

    private func makeListItem(from message: Message) -> EventListItem {
        let fields = EventDisplayFieldReader.fields(from: message)
        let state = fields.eventGuid.map { EventsHelper.shared.getState(of: $0) } ?? ""

        return EventListItem(timestamp: fields.timestamp, state: state)
    }
}
