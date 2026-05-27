//
//  EventExpiryManager.swift
//  Clickstream
//
//  Created by Rishab Habbu on 26/05/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

import Foundation

protocol EventExpirationProtocol {
    func getDefaultExpiration() -> Date
    func getExpiration(for event: ClickstreamEvent) -> Date
}

class EventExpiryManager: EventExpirationProtocol {
    
    let eventExpiryConfig: EventExpirationConfig
        
    init(eventExpiryConfig: EventExpirationConfig) {
        self.eventExpiryConfig = eventExpiryConfig
    }
    
    func getDefaultExpiration() -> Date {
        let default_ttl = eventExpiryConfig.defaultExpiryDays
        let date = Date().addingDays(default_ttl)
        return date
    }
    
    func getExpiration(for event: ClickstreamEvent) -> Date {
        guard !eventExpiryConfig.eventsTTL.isEmpty, let csEventName = event.csEventName else {
            return getDefaultExpiration()
        }
        
        if let ttl = eventExpiryConfig.eventsTTL[csEventName] {
            let date = Date().addingDays(ttl)
            return date
        }
        
        return getDefaultExpiration()
    }
}

class FallbackEventExpirationManager: EventExpirationProtocol {
    
    func getDefaultExpiration() -> Date {
        return Date().addingMonthsWith30days(6)
    }
    
    func getExpiration(for event: ClickstreamEvent) -> Date {
        return getDefaultExpiration()
    }
}


extension Date {
    func addingDays(_ days: Int) -> Date {
        return self.addingTimeInterval(TimeInterval(days) * 60 * 60 * 24)
    }
    
    func addingMonthsWith30days(_ months: Int) -> Date {
        return self.addingTimeInterval(TimeInterval(months) * 60 * 60 * 24 * 30)
    }
}
