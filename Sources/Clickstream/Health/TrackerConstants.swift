//
//  HealthConstants.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 02/05/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import Foundation

public enum TrackedVia: String, Codable {
    case `internal` = "internal" // Track internally via clickstream. Use health proto for it.
    case external = "external" // Track via client. Generates health events in the ClickstreamHealthEvent Contract.
    case both = "both" // Track internally and externally
}

public struct TrackerConstant {
    
    @_spi(ClickstreamInternal) public enum Traces: String {
        case ClickstreamSocketConnectionTime = "ClickstreamSocketConnectionTimeTrace"
    }
    
    public static var traceName = "traceName"
    public static var traceAttributes = "traceAttributes"
    
    //TODO: Added Traces after merging Health tracking
    public static let DebugEventsNotification = NSNotification.Name(rawValue: "ClickstreamDebugNotifications")
    public static let TraceStartNotification = NSNotification.Name(rawValue: "ClickstreamTraceStartNotification")
    public static let TraceStopNotification = NSNotification.Name(rawValue: "ClickstreamTraceEventsNotification")
    
    @_spi(ClickstreamInternal) public static var deviceMake = "Apple"
    @_spi(ClickstreamInternal) public static var deviceOS = "iOS"
    
    @_spi(ClickstreamInternal) public static let appState = "app_state"
    
    public static let eventName = "eventName"
    public static let eventProperties = "event_properties"
    public static let clickstream_timestamp = "clickstream_timestamp"
    public static let clickstream_event_guid = "clickstream_event_guid"
    public static let clickstream_event_batch_guid = "clickstream_event_batch_guid"
    public static let clickstream_sessionId = "clickstream_sessionId"
    public static let clickstream_error_reason = "clickstream_error_reason"
    public static let clickstream_event_guid_list = "clickstream_event_guid_list"
    public static let clickstream_event_count = "clickstream_event_count"
    public static let clickstream_timestamp_list = "clickstream_timestamp_list"
    public static let clickstream_event_batch_guid_list = "clickstream_event_batch_guid_list"
    
    public static let propertyLengthConstraint = 13
    
    @_spi(ClickstreamInternal) public static let HealthEventType = "healthEvent"
    
    public enum EventType: String, Codable {
        case instant = "instant"
        case aggregate = "aggregate"
    }
    
    @_spi(ClickstreamInternal) public static let InstantEvents: [HealthEvents] = [.ClickstreamEventBatchDropped, .ClickstreamConnectionSuccess, .ClickstreamConnectionFailure, .ClickstreamEventBatchErrorResponse, .ClickstreamWriteToSocketFailed, .ClickstreamEventBatchTriggerFailed, .ClickstreamDBCorrupted, .Courier_ClickstreamEventBatchDropped, .Courier_ClickstreamConnectionSuccess, .Courier_ClickstreamConnectionFailure, .Courier_ClickstreamEventBatchErrorResponse, .Courier_ClickstreamWriteToSocketFailed, .Courier_ClickstreamEventBatchTriggerFailed]
}
