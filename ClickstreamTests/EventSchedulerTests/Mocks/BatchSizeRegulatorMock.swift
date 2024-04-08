//
//  BatchSizeRegulatorMock.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 25/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

@testable import Clickstream
import Foundation

final class BatchSizeRegulatorMock: BatchSizeRegulator {
    
    func observe(_ event: Event) { }
    
    func regulatedNumberOfItemsPerBatch(expectedBatchSize: Double) -> Int {
        return 50
    }
}
