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

enum HealthEvents: String, Codable, CaseIterable {
    
    case ClickstreamEventCached = "Clickstream Event Cached" // Clickstream
    case ClickstreamEventBatchCreated = "Clickstream Event Batch Created" // Clickstream
    case ClickstreamBatchSent = "Clickstream Batch Sent" // Clickstream
    case ClickstreamEventBatchSuccessAck = "Clickstream Event Batch Success Ack" // Clickstream
    case ClickstreamFlushOnBackground = "Clickstream Flush On Background" // Clickstream
    case ClickstreamFlushOnForeground = "Clickstream Flush On Foreground" // Clickstream
    
    case ClickstreamEventBatchTriggerFailed = "Clickstream Event Batch Trigger Failed"
    case ClickstreamWriteToSocketFailed = "Clickstream Write to Socket Failed"
    case ClickstreamEventBatchErrorResponse = "Clickstream Event Batch Error response"
    case ClickstreamEventBatchDropped = "Clickstream Event Batch Dropped"
    
    case ClickstreamConnectionSuccess = "Clickstream Connection Success"
    case ClickstreamConnectionFailure = "Clickstream Connection Failure"
    case ClickstreamConnectionDropped = "Clickstream Connection Dropped"
}

enum FailureReason: String, Codable, CaseIterable {
    case ParsingException = "parsing_exception"
    
    case AuthenticationError = "401 Unauthorized"
    case DuplicateID = "Duplicate ID"
    case SOCKET_TIMEOUT = "socket_timeout"
    
    case MAX_USER_LIMIT_REACHED = "max_user_limit_reached"
    case MAX_CONNECTION_LIMIT_REACHED = "max_connection_limit_reached"
    
    case networkUnavailable = "network_unavailable"
    case lowBattery = "low_battery"
    case socket_not_open = "socket_not_open"
}

public struct TrackerConstant {
    
    internal enum Traces: String {
        case ClickstreamSocketConnectionTime = "ClickstreamSocketConnectionTimeTrace"
    }
    
    public static var traceName = "traceName"
    public static var traceAttributes = "traceAttributes"
    
    //TODO: Added Traces after merging Health tracking
    public static let DebugEventsNotification = NSNotification.Name(rawValue: "ClickstreamDebugNotifications")
    public static let TraceStartNotification = NSNotification.Name(rawValue: "ClickstreamTraceStartNotification")
    public static let TraceStopNotification = NSNotification.Name(rawValue: "ClickstreamTraceEventsNotification")
    
    static var deviceMake = "Apple"
    static var deviceOS = "iOS"
    
    static let appState = "app_state"
    
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
    
    static let HealthEventType = "healthEvent"
    
    public enum EventType: String, Codable {
        case instant = "instant"
        case aggregate = "aggregate"
    }
    
    static let InstantEvents: [HealthEvents] = [.ClickstreamEventBatchDropped, .ClickstreamConnectionSuccess, .ClickstreamConnectionFailure, .ClickstreamEventBatchErrorResponse, .ClickstreamWriteToSocketFailed, .ClickstreamEventBatchTriggerFailed]
}
