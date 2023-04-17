//
//  EventStateViewable.swift
//  ClickStream
//
//  Created by Rishav Gupta on 31/03/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

public protocol EventStateViewable: AnyObject {
    /// responsible for sending the events in struct EventData
    func sendEvent(_ event: EventData)
    
    /// updates state with type EventState based on eventGuid or eventBatchGuid
    func updateStatus(providedEventGuid: String?, eventBatchID: String?, state: EventState)
}

extension EventStateViewable {
    /// provides a default implementation of `updateStatus` as for some instance `providedEventGuid` is not passed
    /// and for some instance `eventBatchID` is not passed
    /// - Parameters:
    ///   - providedEventGuid: this is the eventGuid for a particular event
    ///   - eventBatchID: this is the eventBatchGuid for a particular event batch
    ///   - state: this is the state in which the event is in
    func updateStatus(providedEventGuid: String? = nil, eventBatchID: String? = nil, state: EventState) {
        updateStatus(providedEventGuid: providedEventGuid, eventBatchID: eventBatchID, state: state)
    }
}

public enum EventState: CustomStringConvertible {
    case received
    case cached
    case sent
    case ackReceived
    
    public var description: String {
        switch self {
        case .received:
            return "Event Received"
        case .cached:
            return "Event Cached"
        case .sent:
            return "Event Sent to Raccoon"
        case .ackReceived:
            return "Event Acknowledged from Raccoon"
        }
    }
}

public struct EventData {
    /// contains message which has all the event details
    public let msg: Message
    /// contains the state in which the event is in (received, cache, sent or acknowledged)
    public var state: EventState
    /// contains the batchID of the particular event.
    /// Used for mapping it at client end.
    /// When event is acknowledged, we have the event batch ID and not the event ID.
    /// Thus, batch ID is used to update the state of the event to Acknowledged.
    public var batchId: String?
}
