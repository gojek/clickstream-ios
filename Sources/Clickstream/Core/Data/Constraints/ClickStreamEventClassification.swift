//
//  ClickstreamEventClassification.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 27/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

/// Holds the Event classification for Clickstream.
public struct ClickstreamEventClassification: Decodable {
    
    /// Holds all the eventTypes
    private(set) var eventTypes: [EventClassifier]
    
    /// Returns an instance of ClickstreamEventClassification
    public init(eventTypes: [EventClassifier] = [EventClassifier(identifier: "realTime", eventNames: []),
                                                 EventClassifier(identifier: "instant", eventNames: [])]) {
        self.eventTypes = eventTypes
    }
    
    public struct EventClassifier: Decodable {
        
        /// To identify the events. And map between priorities and event names.
        private(set) var identifier: String
        
        /// List of event names under a given category.
        private(set) var eventNames: [String]
        
        public init(identifier: String, eventNames: [String]) {
            self.identifier = identifier
            self.eventNames = eventNames
        }
    }
    
    /// Returns an instance of ClickStreamEventClassification by decoding the json string.
    /// - Parameter json: String that needs to be decoded.
    static func getInstance(from json: String) -> ClickstreamEventClassification? {
        return JSONStringDecoder.decode(json: json, fallbackJson: Constants.Defaults.Configs.eventClassification)
    }
}
