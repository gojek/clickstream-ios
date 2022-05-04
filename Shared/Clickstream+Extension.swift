//
//  Clickstream+Extension.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 04/05/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import Foundation

extension Clickstream {
    
    /// <#Description#>
    /// - Parameter event: <#event description#>
    static func trackHealthEvent(event: AnalysisEvent?) {
        Tracker.sharedInstance?.record(event: event)
    }
}
