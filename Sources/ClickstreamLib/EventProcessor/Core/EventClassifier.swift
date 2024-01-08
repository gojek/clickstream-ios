//
//  EventClassifier.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 03/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol EventClassifierInput { }

protocol EventClassifierOutput {
    func getClassification(eventName: String) -> String?
}

protocol EventClassifier: EventClassifierInput, EventClassifierOutput { }

struct DefaultEventClassifier: EventClassifier {
    
    func getClassification(eventName: String) -> String? {
        let classification = Clickstream.eventClassifier.eventTypes.filter {$0.eventNames.contains(eventName)}
        return (classification.first?.identifier) ?? Clickstream.eventClassifier.eventTypes.first?.identifier
    }
}
