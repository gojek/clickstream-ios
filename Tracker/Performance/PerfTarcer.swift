//
//  PerfTarcer.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 23/02/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import Foundation

protocol Traceable {
    mutating func start()
    mutating func stop()
}

struct Trace: Traceable {
    
    private var isRunning: Bool = false
    
    var name: String
    var attributes: [String:Any]
    
    init(name: String,
         attributes:[String:Any] = [:]) {
        self.name = name
        self.attributes = attributes
    }
    
    mutating func start() {
        if Tracker.debugMode && isRunning == false {
            let notificationDict: [String:Any] = [ClickstreamDebugConstants.traceName: name,
                                    ClickstreamDebugConstants.traceAttributes: attributes]
            NotificationCenter.default.post(name: ClickstreamDebugConstants.TraceStartNotification, object: notificationDict)
            isRunning = true
        }
    }
    
    mutating func stop() {
        if Tracker.debugMode && isRunning {
            isRunning = false
            let notificationDict: [String:Any] = [ClickstreamDebugConstants.traceName: name,
                                    ClickstreamDebugConstants.traceAttributes: attributes]
            NotificationCenter.default.post(name: ClickstreamDebugConstants.TraceStopNotification, object: notificationDict)
        }
    }
}
