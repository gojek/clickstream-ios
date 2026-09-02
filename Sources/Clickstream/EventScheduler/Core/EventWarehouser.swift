//
//  EventWarehouser.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 28/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol EventWarehouser {

    associatedtype EventType = EventPersistable

    /// Call this to schedule an event.
    /// - Parameter event: event object
    func store(_ event: EventType)
    
    /// Call this to stop the scheduler tasks. Meant to be called only when you need to stop tasks and purge resources.
    func stop()
}
