//
//  EventDetailsViewModel.swift
//  EventVisualizer
//
//  Created by Rishav Gupta on 14/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import Foundation
import SwiftProtobuf
import UIKit

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
        displayedMessage = EventPropertyReader.entries(from: message)
    }

    /// Returns the key path displayed at the given row, honouring an active search.
    func keyPath(at indexPath: IndexPath) -> String? {
        let source = (isSearchActive && searchText != "") ? searchedMessage : displayedMessage
        guard let source = source, source.indices.contains(indexPath.row) else { return nil }
        return source[indexPath.row].0
    }

    /// Returns the row index of the given key path in the full (unfiltered) list.
    func rowIndex(ofKeyPath keyPath: String) -> Int? {
        return displayedMessage?.firstIndex { $0.0 == keyPath }
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
