//
//  EventSampler.swift
//  Clickstream
//
//  Created by Rishab Habbu on 01/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//
import Foundation

protocol EventSampler {
    func shouldTrack(event: ClickstreamEvent) -> Bool
}

class DefaultEventSampler: EventSampler {
    
    let configurations: EventSamplerConfiguration
    
    init(config: EventSamplerConfiguration) {
        self.configurations = config
    }
    
    func shouldTrack(event: ClickstreamEvent) -> Bool {
        let eventName = event.eventName
        
        if let overrides = configurations.overrides, let sampleRate = overrides[eventName] {
            let randomValue = Int.random(in: 1...EventSamplerConstants.defaultSampleRate)
            return randomValue <= Int(sampleRate)
        }
        
        return true
    }
}
