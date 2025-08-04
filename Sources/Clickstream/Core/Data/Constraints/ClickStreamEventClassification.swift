//
//  ClickstreamEventClassification.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 27/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

/// Holds the Event classification for Clickstream.
public struct ClickstreamEventClassification {
    
    /// Holds all the eventTypes
    private(set) var eventTypes: [EventClassifier]
    
    /// Returns an instance of ClickstreamEventClassification
    public init(eventTypes: [EventClassifier] = [EventClassifier(identifier: "realTime", eventNames: [], csEventNames: []),EventClassifier(identifier: "instant", eventNames: [], csEventNames: [])]) {
        self.eventTypes = eventTypes
    }
    
    public struct EventClassifier {
        
        /// To identify the events. And map between priorities and event names.
        private(set) var identifier: String
        
        /// List of event names under a given category.
        private(set) var eventNames: [String]
        
        private(set) var csEventNames: [String]
        
        public init(identifier: String, eventNames: [String], csEventNames: [String]) {
            self.identifier = identifier
            self.eventNames = eventNames
            self.csEventNames = csEventNames
        }
    }
}
