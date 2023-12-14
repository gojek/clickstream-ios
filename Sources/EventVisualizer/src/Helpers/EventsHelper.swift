//
//  EventsHelper.swift
//  EventVisualizer
//
//  Created by Rishav Gupta on 29/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import UIKit
import Foundation

struct ClickstreamConnectionStatusView {
    var statusLabel: UILabel
    var statusImage: UIImageView
}

final public class EventsHelper {
    
    private init() {}
    
    /// singleton variable
    public static let shared: EventsHelper = EventsHelper()
    
    /// used for capturing the events sent by Clickstream
    public var eventsCaptured: [EventData] = []
    
    public var clickstreamConnectionState: Clickstream.ConnectionState {
        return Clickstream.getInstance()?.clickstreamConnectionState ?? .failed
    }
    
    /// returns the state of the event given the eventGuid
    public func getState(of providedEventGuid: String) -> String {
        if let foundIndex = indexOfEvent(with: providedEventGuid) {
            return EventsHelper.shared.eventsCaptured[foundIndex].state.description
        }
        return ""
    }
    
    public func startCapturing() {
        #if EVENT_VISUALIZER_ENABLED
        Clickstream.getInstance()?.stateViewer = self
        #endif
    }
    
    public func stopCapturing() {
        #if EVENT_VISUALIZER_ENABLED
        Clickstream.getInstance()?.stateViewer = nil
        #endif
    }
    public func clearData() {
        EventsHelper.shared.eventsCaptured = []
    }
    
    @available(iOS 13.0, *)
    func getCSConnectionStateView(title: UILabel) -> ClickstreamConnectionStatusView {
        let statusLabel = UILabel()
        let stateImage = UIImageView()
        if EventsHelper.shared.clickstreamConnectionState == .connected {
            stateImage.image = UIImage(systemName: "wifi")
            statusLabel.text = "Connected"
        } else {
            stateImage.image = UIImage(systemName: "wifi.slash")
            statusLabel.text = "Not connected"
        }
        statusLabel.font = UIFont.systemFont(ofSize: 10)
        statusLabel.sizeToFit()
//            statusLabel.center = navView.center
        statusLabel.textAlignment = NSTextAlignment.left
        statusLabel.frame = CGRect(x: title.frame.origin.x, y: title.frame.maxY, width: title.frame.size.width, height: statusLabel.frame.size.height)

        /// Setting the image frame so that it's immediately before the text:
        stateImage.frame = CGRect(x: statusLabel.frame.minX - 20, y: statusLabel.frame.origin.y, width: 15, height: 15)
        stateImage.contentMode = UIView.ContentMode.scaleAspectFit
        return ClickstreamConnectionStatusView(statusLabel: statusLabel, statusImage: stateImage)
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
        if let providedEventGuid = providedEventGuid,
            let foundIndex = indexOfEvent(with: providedEventGuid),
            foundIndex < EventsHelper.shared.eventsCaptured.count {
            
            EventsHelper.shared.eventsCaptured[foundIndex].state = state
            if let eventBatch = eventBatch {
                EventsHelper.shared.eventsCaptured[foundIndex].batchId = eventBatch
            }
        } else if let eventBatch = eventBatch {
            let foundIndexs = indexOfEventBatch(with: eventBatch)
            for eventIndex in foundIndexs {
                if eventIndex < EventsHelper.shared.eventsCaptured.count {
                    EventsHelper.shared.eventsCaptured[eventIndex].state = state
                }
            }
        }
    }
    
    private func indexOfEvent(with eventGuid: String) -> Int? {
        let events = EventsHelper.shared.eventsCaptured.map { $0.msg }
        for (index, message) in events.enumerated() {
            if let productComm = message as? CollectionMapper {
                let flattenedDict = productComm.asDictionary
                if let currentEventGuid = flattenedDict[Constants.EventVisualizer.eventGuid] as? String, currentEventGuid == eventGuid {
                    return index
                } else if let currentEventGuid = flattenedDict["storage.\(Constants.EventVisualizer.eventGuid)"] as? String,
                          currentEventGuid == eventGuid {
                    return index
                } else if let currentEventGuid = flattenedDict[Constants.EventVisualizer.guid] as? String,
                          currentEventGuid == eventGuid {
                    return index
                } else if let currentEventGuid = flattenedDict["storage.meta.storage.\(Constants.EventVisualizer.eventGID)"] as? String,
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
