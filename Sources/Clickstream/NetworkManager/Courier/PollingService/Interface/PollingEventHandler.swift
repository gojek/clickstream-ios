//
//  EventHanlder.swift
//  FallbackPollingService
//
//  Created by Alfian Losari on 07/02/23.
//

import Foundation

protocol PollingEvent { }

protocol PollingEventHandler: AnyObject {
    func onEvent(_ event: PollingEvent)
}

struct PollingTriggeredEvent: PollingEvent {
    let source: String
    let type: PollingType
}

struct PollingMessageReceivedEvent: PollingEvent {
    let source: PollingMessageSource
}

struct PollingMessageReceiveFailureEvent: PollingEvent {
    let source: PollingMessageSource
    let error: String
}
