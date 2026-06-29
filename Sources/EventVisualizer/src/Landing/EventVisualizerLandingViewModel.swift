//
//  EventVisualizerLandingViewModel.swift
//  EventVisualizer
//
//  Created by Rishav Gupta on 07/03/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol EventVisualizerLandingViewModelInput: AnyObject {
    
    var eventsDict: [String: [String: [EventData]]] { get set }
    
    var sectionCount: Int { get }
    
    var isSearchActive: Bool { get set }
        
    /// to store searched text
    var searchText: String { get set }
    
    /// to store the filtered results which would be array of event names without duplication
    var filterResult: [String] { get set }
    
    func headerTitle(section: Int) -> String
    
    func cellsCount(section: Int) -> Int
    
    /// this would take in array of tuple(key, value) pair and calculate and return array of event names as filtered result
    func getFilteredEvents(data: [(String, String)]) -> [String]
        
    func viewDidLoad()
    
    func cellViewModel(for indexPath: IndexPath) -> EventsListingTableViewCell.ViewModel
    
    func didSelectRow(at indexPath: IndexPath) -> [EventData]?
}

final class EventVisualizerLandingViewModel: EventVisualizerLandingViewModelInput {
    
    /// [proto: [EventName: [EventData]]]
    var eventsDict: [String: [String: [EventData]]] = [:]
    
    var sectionCount: Int {
        /// if searching or filtering then there would be no section division
        if (isSearchActive && searchText != "") || !filterResult.isEmpty {
            return 1
        } else {
            return eventsDict.keys.count
        }
    }
    
    var isSearchActive: Bool = false
    
    var searchText: String = ""
    
    var filterResult: [String] = []
        
    private var searchResult: [String] = []
    
    private var protoToEventDict: [String: [EventData]] = [:]
    
    func cellViewModel(for indexPath: IndexPath) -> EventsListingTableViewCell.ViewModel {
        
        var eventName = ""
        if isSearchActive && searchText != "" {
            /// searchResult contain event names
            eventName = searchResult[indexPath.row]
        } else if !filterResult.isEmpty {
            /// filterResult contain event names
            eventName = filterResult[indexPath.row]
        } else {
            /// get all protos
            let protoArray = eventsDict.map { $0.key }
            /// get proto name of indexPath.section
            let protoInSection = protoArray[indexPath.section]
            /// get event dict of that proto in [String: [EventData]] form
            if let eventDictInproto = eventsDict[protoInSection] {
                /// get all event names that that particular proto
                let eventsListInproto = eventDictInproto.map { $0.key }
                /// get event name of indexPath.row
                let messageInEvent = eventsListInproto[indexPath.row]
                if let firstEvent = eventDictInproto[messageInEvent]?.first {
                    if let summaryName = firstEvent.displaySummary?.eventName, !summaryName.isEmpty {
                        eventName = summaryName
                    } else {
                        eventName = EventDisplayFieldReader.eventName(from: firstEvent.msg) ?? messageInEvent
                    }
                }
            }
            if eventName == "" {
                /// if event name is empty then use proto name instead
                eventName = protoInSection
            }
        }
        return EventsListingTableViewCell.ViewModel(
                    name: eventName,
                    value: ""
        )
    }
    
    func headerTitle(section: Int) -> String {
        if (isSearchActive && searchText != "") || !filterResult.isEmpty {
            return ""
        } else {
            /// get all protos
            let keysArray = eventsDict.map { $0.key }
            /// get proto name of section
            return "\(keysArray[section])"
        }
    }
    
    func cellsCount(section: Int) -> Int {
        if isSearchActive && searchText != "" {
            /// get all values of proto keys which gives [[eventName: [EventData]]] and then flatten it out to [eventName: [EventData]]
            let eventInDict = eventsDict.map { $0.value }.flatMap { $0 }
            /// get all event names
            let events = eventInDict.map { $0.key }
            /// get all event names which contain the searchText
            self.searchResult = events.filter { $0.lowercased().contains(searchText.lowercased()) }
            return searchResult.count
        } else if !filterResult.isEmpty {
            /// get all values of proto keys which gives [[eventName: [EventData]]] and then flatten it out to [eventName: [EventData]]
            let eventInDict = eventsDict.map { $0.value }.flatMap { $0 }
            /// get all event names
            let events = eventInDict.map { $0.key }
            /// get the intersection of All-event-names and filtered-event-names, such that only unique names are expected
            self.filterResult = events.filter { filterResult.contains($0) }
            return filterResult.count
        } else {
            /// get all protos
            let protoArray = eventsDict.map { $0.key }
            /// get proto name of section
            let protoInSection = protoArray[section]
            /// get events in selected proto
            if let eventsInproto = eventsDict[protoInSection] {
                return eventsInproto.count
            }
        }
        return 0
    }
    
    func viewDidLoad() {
        processEvents()
        /// getting events in form of [String: [EventData]] from clickstream sdk as [proto: [EventData]]
        for (proto, eventsArray) in protoToEventDict {
            var eventsByName: [String: [EventData]] = [:]
            for event in eventsArray {
                let eventName: String
                if let summaryName = event.displaySummary?.eventName, !summaryName.isEmpty {
                    eventName = summaryName
                } else {
                    eventName = EventDisplayFieldReader.eventName(from: event.msg) ?? proto
                }

                if let value = eventsByName[eventName] {
                    eventsByName[eventName] = value + [event]
                } else {
                    eventsByName[eventName] = [event]
                }
            }
            eventsDict[proto] = eventsByName
        }
    }
    
    ///  Action on selecting the row
    /// - Parameter indexPath: indexPath of that cell
    /// - Returns: returning array of events for the selected row
    func didSelectRow(at indexPath: IndexPath) -> [EventData]? {
        if isSearchActive && searchText != "" {
            /// get all values of proto keys which gives [[eventName: [EventData]]] and then flatten it out to [eventName: [EventData]]
            let eventInDict = eventsDict.map { $0.value }.flatMap { $0 }
            let eventSelected = searchResult[indexPath.row]
            let events = eventInDict.filter { $0.key == eventSelected }
            if let messagesInEvent = events.first?.value {
                return messagesInEvent
            }
        } else if !filterResult.isEmpty {
            /// get all values of proto keys which gives [[eventName: [EventData]]] and then flatten it out to [eventName: [EventData]]
            let eventInDict = eventsDict.map { $0.value }.flatMap { $0 }
            let eventSelected = filterResult[indexPath.row]
            let events = eventInDict.filter { $0.key == eventSelected }
            if let messagesInEvent = events.first?.value {
                return messagesInEvent
            }
        } else {
            /// get all protos
            let protoArray = eventsDict.map { $0.key }
            /// get proto name of section
            let protoInSection = protoArray[indexPath.section]
            if let eventDictInProto = eventsDict[protoInSection] {
                let eventsListInProto = eventDictInProto.map { $0.key }
                let eventSelected = eventsListInProto[indexPath.row]
                if let messagesInEvent = eventDictInProto[eventSelected] {
                    return messagesInEvent
                }
            }
        }
        return nil
    }
    
    /// Filtering the event names corresponding the filter key-value pair selected
    /// - Parameter data: array of tuple (key-value) pair of the user input from the filter screen
    /// - Returns: array of event names which corresponding to the filter key-value pair selected
    func getFilteredEvents(data: [(String, String)]) -> [String] {
        var filteredEventNames: [String] = []
        /// getting [[EventData]] and flattening it to [EventData]
        let eventArray = protoToEventDict.map { $0.value }.flatMap { $0 }
        for event in eventArray {
            if let protoComm = event.msg as? CollectionMapper {
                /// converting [Message] to [String: Any]
                var messAsDict = protoComm.asDictionary
                if let eventGuid = messAsDict[Constants.EventVisualizer.eventGuid] as? String {
                    messAsDict["state"] = EventsHelper.shared.getState(of: eventGuid)
                } else if let eventGuid = messAsDict[Constants.EventVisualizer.guid] as? String {
                    messAsDict["state"] = EventsHelper.shared.getState(of: eventGuid)
                }
                var isMessageConformingtoAllFilters = false
                /// iterate over the filtered data entered by user and check which event contains these key-value pairs -> append event name of that event to filteredEventNames
                for values in data {
                    let userInputKey = values.0.lowercased()
                    let userInputValue = values.1.lowercased()
                    guard let mappedProtoKey = checkIfKeyIsPresent(message: messAsDict, userInputKey: userInputKey, userInputValue: userInputValue) else {
                        isMessageConformingtoAllFilters = false
                        break
                    }
                    if "\(messAsDict[mappedProtoKey] ?? "")".lowercased().contains(userInputValue) {
                        isMessageConformingtoAllFilters = true
                    } else {
                        isMessageConformingtoAllFilters = false
                    }
                }
                if isMessageConformingtoAllFilters {
                    if let eventName = event.displaySummary?.eventName, !eventName.isEmpty {
                        filteredEventNames.append(eventName)
                    } else if let eventName = messAsDict["eventName"] as? String {
                        filteredEventNames.append(eventName)
                    } else if let eventName = messAsDict["storage.eventName"] as? String {
                        filteredEventNames.append(eventName)
                    }
                }
            }
        }
        return filteredEventNames
    }
    
    func checkIfKeyIsPresent(message: [String: Any], userInputKey: String, userInputValue: String) -> String? {
        let listOfKeys = message.map { $0.key }
        for key in listOfKeys {
            if key.lowercased().contains(userInputKey) {
                if "\(message[key] ?? "")".lowercased().contains(userInputValue) {
                    return key
                }
            }
        }
        return nil
    }
    
    /// Capturing events in Clickstream static dictionary with type of event as key and event message as value [proto: [EventData]]
    func processEvents() {
        let eventArray = EventsHelper.shared.eventsCaptured
        
        for event in eventArray {
            if let typeOfEvent = type(of: event.msg).protoMessageName.components(separatedBy: ".").last?.lowercased() {
                if let value = protoToEventDict[typeOfEvent] {
                    protoToEventDict[typeOfEvent] = value + [event]
                } else {
                    protoToEventDict[typeOfEvent] = [event]
                }
            }
        }
    }
}
