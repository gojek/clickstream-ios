//
//  EventsHelper.swift
//  EventVisualizer
//
//  Created by Rishav Gupta on 29/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import Foundation

final public class EventsHelper {
    
    private init() {}
    
    /// singleton variable
    public static let shared: EventsHelper = EventsHelper()
    
    /// used for capturing the events sent by Clickstream
    public var eventsCaptured: [EventData] = []
    
    /// returns the state of the event given the eventGuid
    public func getState(of providedEventGuid: String) -> String {
        if let foundIndex = indexOfEvent(with: providedEventGuid) {
            return EventsHelper.shared.eventsCaptured[foundIndex].state.description
        }
        return ""
    }
    
    public func startCapturing() {
        Clickstream.stateViewer = self
    }
    
    public func stopCapturing() {
        Clickstream.stateViewer = nil
    }
    public func clearData() {
        EventsHelper.shared.eventsCaptured = []
    }
}

extension EventsHelper: EventStateViewable {
    public func sendEvent(_ event: EventData) {
        /// all events sent by Clickstream is stored here in an array
        EventsHelper.shared.eventsCaptured.append(event)
    }
    
    /// When providedEventGuid is not nil, then: Update the state of the event and
    /// update the eventBatchGuid of the event which would be used later to
    /// update the state when eventGuid is not present.
    /// when providedEventGuid is nil then,
    /// find the event based upon eventBatchGuid and update the state
    /// - Parameters:
    ///   - providedEventGuid: this is the eventGuid for a particular event
    ///   - eventBatch: this is the eventBatchGuid for a particular event batch
    ///   - state: this is the state in which the event is in
    public func updateStatus(providedEventGuid: String? = nil, eventBatchID eventBatch: String? = nil, state: EventState) {
        if let providedEventGuid = providedEventGuid, let foundIndex = indexOfEvent(with: providedEventGuid) {
            
            EventsHelper.shared.eventsCaptured[foundIndex].state = state
            if let eventBatch = eventBatch {
                EventsHelper.shared.eventsCaptured[foundIndex].batchId = eventBatch
            }
        } else if let eventBatch = eventBatch {
            let foundIndexs = indexOfEventBatch(with: eventBatch)
            for eventIndex in foundIndexs {
                EventsHelper.shared.eventsCaptured[eventIndex].state = state
            }
        }
    }
    
    private func indexOfEvent(with eventGuid: String) -> Int? {
        let events = EventsHelper.shared.eventsCaptured.map { $0.msg }
        for (index, message) in events.enumerated() {
            if let productComm = message as? CollectionMapper {
                let flattenedDict = productComm.asDictionary
                if let currentEventGuid = flattenedDict[Constants.EventVisualizer.guid] as? String, currentEventGuid == eventGuid {
                    return index
                } else if let currentEventGuid = flattenedDict["storage.\(Constants.EventVisualizer.guid)"] as? String,
                            currentEventGuid == eventGuid {
                    return index
                }
            }
        }
        return nil
    }
    
    private func indexOfEventBatch(with eventBatchGuid: String) -> [Int] {
        var foundEventsArray: [Int] = []
        let batchesId = EventsHelper.shared.eventsCaptured.map { $0.batchId }
        for (index, batchId) in batchesId.enumerated() {
            if batchId == eventBatchGuid {
                foundEventsArray.append(index)
            }
        }
        return foundEventsArray
    }
}
