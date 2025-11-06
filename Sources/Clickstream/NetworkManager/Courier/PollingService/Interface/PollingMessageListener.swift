//
//  MessageListener.swift
//  FallbackPollingService
//
//  Created by Alfian Losari on 07/02/23.
//

import Foundation

protocol PollingMessageListener {
    
    associatedtype T
    
    func onMessageReceived(_ message: T, source: PollingMessageSource)
}
