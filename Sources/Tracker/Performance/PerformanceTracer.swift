//
//  PerformanceTracer.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 08/04/24.
//  Copyright © 2024 Gojek. All rights reserved.
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
            let notificationDict: [String:Any] = [TrackerConstant.traceName: name,
                                                  TrackerConstant.traceAttributes: attributes]
            NotificationCenter.default.post(name: TrackerConstant.TraceStartNotification, object: notificationDict)
            isRunning = true
        }
    }
    
    mutating func stop() {
        if Tracker.debugMode && isRunning {
            isRunning = false
            let notificationDict: [String:Any] = [TrackerConstant.traceName: name,
                                                  TrackerConstant.traceAttributes: attributes]
            NotificationCenter.default.post(name: TrackerConstant.TraceStopNotification, object: notificationDict)
        }
    }
}

