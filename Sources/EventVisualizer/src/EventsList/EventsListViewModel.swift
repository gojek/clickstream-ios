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
        messages: [EventData]?,
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

    private var events: [EventData] = []
    private var listItems: [EventListItem] = []

    private let processingQueue = DispatchQueue(label: "com.clickstream.eventvisualizer.eventslist.processing", qos: .userInitiated)

    var cellsCount: Int {
        return listItems.count
    }

    func viewDidLoad(
        messages: [EventData]?,
        progress: @escaping (_ processedCount: Int, _ totalCount: Int) -> Void,
        completion: @escaping () -> Void
    ) {
        guard let messages = messages else {
            self.events = []
            self.listItems = []
            progress(0, 0)
            completion()
            return
        }

        self.events = Array(messages.reversed())

        let totalCount = self.events.count
        let progressBatchSize = max(1, totalCount / 20)
        DispatchQueue.main.async {
            progress(0, totalCount)
        }

        processingQueue.async { [weak self] in
            guard let self = self else { return }

            var renderedItems: [EventListItem] = []
            renderedItems.reserveCapacity(totalCount)

            for (index, event) in self.events.enumerated() {
                renderedItems.append(self.makeListItem(from: event))
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
        return events[indexPath.row].msg
    }

    private func makeListItem(from event: EventData) -> EventListItem {
        let timestamp = event.displaySummary?.timestamp ?? EventDisplayFieldReader.timestampString(from: event.msg) ?? ""
        let state = event.state.description
        return EventListItem(timestamp: timestamp, state: state)
    }
}
