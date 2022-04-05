//
//  EventClassifier.swift
//  ClickStream
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
        let classification = ClickStream.eventClassifier.eventTypes.filter {$0.eventNames.contains(eventName)}
        return (classification.first?.identifier) ?? ClickStream.eventClassifier.eventTypes.first?.identifier
    }
}
