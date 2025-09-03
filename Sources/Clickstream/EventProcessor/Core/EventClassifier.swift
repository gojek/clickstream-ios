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
    func getClassification(event: ClickstreamEvent) -> String?
}

protocol EventClassifier: EventClassifierInput, EventClassifierOutput { }

struct DefaultEventClassifier: EventClassifier {
    
    func getClassification(event: ClickstreamEvent) -> String? {
        let classification = Clickstream.eventClassifier.eventTypes.filter({$0.eventNames.contains(event.eventName)})
        // Once this is stable in next 2 versions we can remove the else part completely
        if Clickstream.priorityEventsEnabled {
            if let identifier = classification.first?.identifier {
                return identifier
            }
            if let csEventName = event.csEventName {
                let eventClassification = Clickstream.eventClassifier.eventTypes.filter({$0.csEventNames.contains(csEventName)})
                return (eventClassification.first?.identifier) ?? Clickstream.eventClassifier.eventTypes.first?.identifier
            }
            return Clickstream.eventClassifier.eventTypes.first?.identifier
        } else {
            return (classification.first?.identifier) ?? Clickstream.eventClassifier.eventTypes.first?.identifier
        }
    }
}
