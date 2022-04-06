//
//  Connectable+Heartbeat.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 27/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol HeartBeatable {
    
    /// Sends pingFrame with specified data.
    /// - Parameter data: Data to be sent for pinfgFrame.
    func sendPing(_ data: Data)
    
    /// Stop pings.
    func stopPing()
}
