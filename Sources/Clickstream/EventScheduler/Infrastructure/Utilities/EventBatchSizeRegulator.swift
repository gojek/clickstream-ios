//
//  EventBatchSizeRegulator.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 16/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation

protocol BatchSizeRegulatorInputs {
    func observe(_ event: Event)
}

protocol BatchSizeRegulatorOutputs {
    func regulatedNumberOfItemsPerBatch(expectedBatchSize: Double) -> Int
}

protocol BatchSizeRegulator: BatchSizeRegulatorInputs, BatchSizeRegulatorOutputs {}

final class DefaultBatchSizeRegulator: BatchSizeRegulator {
    
    private var totalDataFlow: Int = 0
    private var totalEventCount: Int = 0
    private let userDefaultKey: String

    init(userDefaultKey: String = "regulatedNumberOfItemsPerBatch") {
        self.userDefaultKey = userDefaultKey
    }

    func regulatedNumberOfItemsPerBatch(expectedBatchSize: Double) -> Int {
        if self.totalEventCount > 0 && self.totalDataFlow > 0 {
            let avgSizeOfEvents = self.totalDataFlow/self.totalEventCount
            let regulatedNumberOfItemsPerBatch = Int(expectedBatchSize)/avgSizeOfEvents
            UserDefaults.standard.set(regulatedNumberOfItemsPerBatch, forKey: self.userDefaultKey)
            UserDefaults.standard.synchronize()
        }
        return UserDefaults.standard.integer(forKey: self.userDefaultKey)
    }
        
    func observe(_ event: Event) {
        self.totalDataFlow += event.eventProtoData.count
        self.totalEventCount += 1
    }
}
