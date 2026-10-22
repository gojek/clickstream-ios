import Foundation

@_spi(ClickstreamInternal) public enum HealthEvents: String, Codable, CaseIterable {
    
    // WebSocket Health Events
    case ClickstreamEventCached = "Clickstream Event Cached" // Clickstream
    case ClickstreamEventBatchCreated = "Clickstream Event Batch Created" // Clickstream
    case ClickstreamBatchSent = "Clickstream Batch Sent" // Clickstream
    case ClickstreamEventBatchSuccessAck = "Clickstream Event Batch Success Ack" // Clickstream
    case ClickstreamEventBatchRetryFailed = "Clickstream Event Batch Retry Failed" // Clickstream
    case ClickstreamFlushOnBackground = "Clickstream Flush On Background" // Clickstream
    case ClickstreamFlushOnForeground = "Clickstream Flush On Foreground" // Clickstream
    
    case ClickstreamEventBatchTriggerFailed = "Clickstream Event Batch Trigger Failed"
    case ClickstreamWriteToSocketFailed = "Clickstream Write to Socket Failed"
    case ClickstreamEventBatchErrorResponse = "Clickstream Event Batch Error response"
    case ClickstreamEventBatchDropped = "Clickstream Event Batch Dropped"
    case ClickstreamDBCorrupted = "Clickstream DB Corrupted"
    
    case ClickstreamConnectionSuccess = "Clickstream Connection Success"
    case ClickstreamConnectionFailure = "Clickstream Connection Failure"
    case ClickstreamConnectionDropped = "Clickstream Connection Dropped"
    
    // Courier Health Events
    case Courier_ClickstreamEventReceived = "Courier_Clickstream Event Received" // Clickstream
    case Courier_ClickstreamEventNotCached = "Courier_Clickstream Event Not Cached" // Clickstream
    case Courier_ClickstreamEventCached = "Courier_Clickstream Event Cached" // Clickstream
    case Courier_ClickstreamEventBatchCreated = "Courier_Clickstream Event Batch Created" // Clickstream
    case Courier_ClickstreamBatchSent = "Courier_Clickstream Batch Sent" // Clickstream
    case Courier_ClickstreamEventBatchSuccessAck = "Courier_Clickstream Event Batch Success Ack" // Clickstream
    case Courier_ClickstreamFlushOnBackground = "Courier_Clickstream Flush On Background" // Clickstream
    case Courier_ClickstreamFlushOnForeground = "Courier_Clickstream Flush On Foreground" // Clickstream
    
    case Courier_ClickstreamEventBatchTriggerFailed = "Courier_Clickstream Event Batch Trigger Failed"
    case Courier_ClickstreamWriteToSocketFailed = "Courier_Clickstream Write to Socket Failed"
    case Courier_ClickstreamEventBatchErrorResponse = "Courier_Clickstream Event Batch Error response"
    case Courier_ClickstreamEventBatchDropped = "Courier_Clickstream Event Batch Dropped"
    
    case Courier_ClickstreamConnectionSuccess = "Courier_Clickstream Connection Success"
    case Courier_ClickstreamConnectionFailure = "Courier_Clickstream Connection Failure"
    case Courier_ClickstreamConnectionDropped = "Courier_Clickstream Connection Dropped"
}

@_spi(ClickstreamInternal) public enum FailureReason: String, Codable, CaseIterable {
    case ParsingException = "parsing_exception"
    
    case AuthenticationError = "401 Unauthorized"
    case DuplicateID = "Duplicate ID"
    case SOCKET_TIMEOUT = "socket_timeout"
    
    case MAX_USER_LIMIT_REACHED = "max_user_limit_reached"
    case MAX_CONNECTION_LIMIT_REACHED = "max_connection_limit_reached"
    
    case networkUnavailable = "network_unavailable"
    case lowBattery = "low_battery"
    case socket_not_open = "socket_not_open"
    case db_corrupted = "db_corrupted"
}

