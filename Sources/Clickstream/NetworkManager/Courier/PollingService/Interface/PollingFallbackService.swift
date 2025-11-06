//
//  PollingFallbackService.swift
//  PollingFallbackService
//
//  Created by Alfian Losari on 03/02/23.
//

import Foundation

protocol PollingFallbackServiceInterface {
    var isStarted: Bool { get }

    func start()
    func stop()
}

protocol PollingService: AnyObject {
    func enablePolling(source: String)
    func disablePolling(source: String)

    var operationQueue: OperationQueue { get }
}

protocol FallbackToPollingConfig {
    var pollingInterval: TimeInterval { get }
}

protocol FallbackPolicy {
    func start(service: PollingService)
    func stop()
}
