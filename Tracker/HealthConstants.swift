//
//  HealthConstants.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 02/05/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import Foundation

public enum ClickstreamDebugConstants {
    // MARK: - Strings
    enum Strings {
        static var deviceMake = "Apple"
        static var deviceOS = "iOS"
    }
    
    internal enum TrackedVia: String, Codable {
        case clickstream = "clickstream"
        case cleverTap = "cleverTap"
    }
    
    internal enum Traces: String {
        case ClickstreamSocketConnectionTime = "ClickstreamSocketConnectionTimeTrace"
    }
    
    static let HealthEventType = "healthEvent"
    
    public static let DebugEventsNotification = NSNotification.Name(rawValue: "ClickstreamDebugNotifications")
    public static let TraceStartNotification = NSNotification.Name(rawValue: "ClickstreamTraceStartNotification")
    public static let TraceStopNotification = NSNotification.Name(rawValue: "ClickstreamTraceEventsNotification")

    public static let propertyLengthConstraint = 13
    
    public static let eventName = "eventName"
    public static let eventProperties = "event_properties"
    public static let clickstream_sessionId = "clickstream_sessionId"
    public static let bucketType = "bucket_type"
    public static let clickstream_event_batch_guid_list = "clickstream_event_batch_guid_list"
    public static let clickstream_event_guid_list = "clickstream_event_guid_list"
    public static let clickstream_event_batch_guid = "clickstream_event_batch_guid"
    public static let clickstream_event_guid = "clickstream_event_guid"
    public static let clickstream_error_reason = "clickstream_error_reason"
    public static let clickstream_event_count = "clickstream_event_count"
    public static let clickstream_timestamp = "clickstream_timestamp"
    public static let clickstream_timestamp_list = "clickstream_timestamp_list"
    
    public static var traceName = "traceName"
    public static var traceAttributes = "traceAttributes"
    
    public struct Health {
        
        enum ErrorReasons: String {
            case failedToRetrieveCommonProperties = "failedToRetrieveCommonProperties"
            case failedToRetrieveClassification = "failedToRetrieveClassification"
            case failedToConvertToDEEventProto = "failedToConvertToDEEventProto"
        }
        
        public enum Events: String, Codable, CaseIterable {
            
            case ClickstreamFailedInit = "Clickstream Failed Init"
            case ClickstreamEventPushed = "Clickstream HostApp Event Pushed"
            case ClickstreamEventReceived = "Clickstream Event Received" // Clickstream
            case ClickstreamEventObjectCreated = "Clickstream Event Object Created" // Clickstream
            case ClickstreamEventCached = "Clickstream Event Cached" // Clickstream
            case ClickstreamEventBatchTriggerFailed = "Clickstream Event Batch Trigger Failed"
            case ClickstreamEventBatchCreated = "Clickstream Event Batch Created" // Clickstream
            case ClickstreamWriteToSocketFailed = "Clickstream Write to Socket Failed"
            case ClickstreamConnectionFailed = "Clickstream Connection Failed"
            case ClickstreamBatchSent = "Clickstream Batch Sent" // Clickstream
            case ClickstreamEventBatchSuccessAck = "Clickstream Event Batch Success Ack" // Clickstream
            case ClickstreamEventBatchErrorResponse = "Clickstream Event Batch Error response"
            case ClickstreamEventBatchTimeout = "Clickstream Event Batch Timeout"
            case ClickstreamFlushOnBackground = "Clickstream Flush On Background" // Clickstream
            case ClickstreamEventObjectCreationFailed = "Clickstream Event Object Creation Failed"
        }
        
        public enum EventReason: String, Codable, CaseIterable {
            case ParsingException = "parsing_exception"
            
            case AuthenticationError = "401 Unauthorized"
            case DuplicateID = "Duplicate ID"
            case SOCKET_TIMEOUT = "socket_timeout"
            
            case MAX_USER_LIMIT_REACHED = "max_user_limit_reached"
            case MAX_CONNECTION_LIMIT_REACHED = "max_connection_limit_reached"
            
            case networkUnavailable = "network_unavailable"
            case lowBattery = "low_battery"
            
            case token_not_found = "token_not_found"
            case configs_not_found = "configs_not_found"
            case feature_disabled = "feature_disabled"
        }
        
        public enum EventType: String, Codable {
            case instant = "instant"
            case aggregate = "aggregate"
        }
        
        static let InstantEvents: [Events] = [.ClickstreamFailedInit, .ClickstreamEventBatchTimeout]
        static let AggregateEvents: [Events] = [.ClickstreamEventReceived, .ClickstreamEventObjectCreated,
                                                .ClickstreamBatchSent, .ClickstreamEventBatchTriggerFailed,
                                                .ClickstreamEventBatchSuccessAck, .ClickstreamConnectionFailed,
                                                .ClickstreamEventBatchErrorResponse, .ClickstreamFlushOnBackground,
                                                .ClickstreamEventBatchCreated,.ClickstreamEventObjectCreationFailed]
        
        static let trackedViaClickstream: [Events] = [.ClickstreamEventReceived, .ClickstreamEventObjectCreated,
                                                      .ClickstreamEventCached, .ClickstreamEventBatchCreated,
                                                      .ClickstreamBatchSent, .ClickstreamEventBatchSuccessAck,
                                                      .ClickstreamFlushOnBackground]
    }
    
    struct Performance {
        
        public enum Events: String, Codable {
            case ClickstreamEventBatchLatency = "Clickstream Event Batch Latency"
            case ClickstreamEventWaitTime = "Clickstream Event Wait Time"
            case ClickstreamBatchSize = "Clickstream Batch Size"
            case ClickstreamEventBatchWaitTime = "Clickstream Event Batch Wait Time"
        }
        
        enum BucketType:Int, Codable, Hashable {
            // Batch Latency
            case LT_1sec_2G
            case LT_1sec_3G
            case LT_1sec_4G
            case LT_1sec_WIFI
            
            case MT_1sec_2G
            case MT_1sec_3G
            case MT_1sec_4G
            case MT_1sec_WIFI
            
            case MT_3sec_2G
            case MT_3sec_3G
            case MT_3sec_4G
            case MT_3sec_WIFI
            
            // Batch Size
            case LT_10KB
            case MT_10KB
            case MT_20KB
            case MT_50KB
            
            // Event Wait Time
            case LT_5sec
            case LT_10sec
            case MT_10sec
            case MT_20sec
            
            // Event Batch Wait Time
            case LT_5sec_batch
            case LT_10sec_batch
            case MT_10sec_batch
            case MT_20sec_batch
            
            var description: String {
                switch self {
                // Batch Latency
                case .LT_1sec_2G:         return "2G_LT_1sec"
                case .LT_1sec_3G:         return "3G_LT_1sec"
                case .LT_1sec_4G:         return "4G_LT_1sec"
                case .LT_1sec_WIFI:       return "WIFI_LT_1sec"
                    
                case .MT_1sec_2G:         return "2G_MT_1sec"
                case .MT_1sec_3G:         return "3G_MT_1sec"
                case .MT_1sec_4G:         return "4G_MT_1sec"
                case .MT_1sec_WIFI:       return "WIFI_MT_1sec"
                    
                case .MT_3sec_2G:         return "2G_MT_3sec"
                case .MT_3sec_3G:         return "3G_MT_3sec"
                case .MT_3sec_4G:         return "4G_MT_3sec"
                case .MT_3sec_WIFI:       return "WIFI_MT_3sec"
                    
                // Batch Size
                case .LT_10KB:            return "LT_10KB"
                case .MT_10KB:            return "MT_10KB"
                case .MT_20KB:            return "MT_20KB"
                case .MT_50KB:            return "MT_50KB"
                    
                // Event and Event Batch Wait Time
                case .LT_5sec, .LT_5sec_batch:            return "LT_5sec"
                case .LT_10sec, .LT_10sec_batch:          return "LT_10sec"
                case .MT_10sec, .MT_10sec_batch:          return "MT_10sec"
                case .MT_20sec, .MT_20sec_batch:          return "MT_20sec"
                    
                }
            }
        }
    }
}
