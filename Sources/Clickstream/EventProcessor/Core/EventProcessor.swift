//
//  EventProcessor.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 03/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol EventProcessorInput {
    func createEvent(event: ClickstreamEvent, isUserAuthenticated: Bool)
    func createBinaryEvent(event: CSBinaryEvent, isUserAuthenticated: Bool)
}

protocol EventProcessorOutput { }

protocol EventProcessor: EventProcessorInput, EventProcessorOutput { }
