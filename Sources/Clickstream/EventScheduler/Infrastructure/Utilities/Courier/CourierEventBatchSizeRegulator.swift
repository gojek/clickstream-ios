//
//  CourierEventBatchSizeRegulator.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 06/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

final class CourierEventBatchSizeRegulator: BatchSizeRegulator {
    
    private var totalDataFlow: Int = 0
    private var totalEventCount: Int = 0
    
    func regulatedNumberOfItemsPerBatch(expectedBatchSize: Double) -> Int {
        if self.totalEventCount > 0 && self.totalDataFlow > 0 {
            let avgSizeOfEvents = self.totalDataFlow/self.totalEventCount
            let regulatedNumberOfItemsPerBatch = Int(expectedBatchSize)/avgSizeOfEvents
            UserDefaults.standard.set(regulatedNumberOfItemsPerBatch, forKey: "regulatedNumberOfItemsPerBatchCourier")
            UserDefaults.standard.synchronize()
        }
        return UserDefaults.standard.integer(forKey: "regulatedNumberOfItemsPerBatchCourier")
    }
        
    func observe(_ event: Event) {
        self.totalDataFlow += event.eventProtoData.count
        self.totalEventCount += 1
    }
}
