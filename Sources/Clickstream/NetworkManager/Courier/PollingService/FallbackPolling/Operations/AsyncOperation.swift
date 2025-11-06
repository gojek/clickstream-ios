//
//  AsyncOperation.swift
//  CourierFallbackPollingService
//
//  Created by Alfian Losari on 08/02/23.
//

import Foundation

open class AsyncOperation: BaseAsyncOperation {
    
    let delay: TimeInterval
    let delayCallback: () -> Void
    let dispatchQueue: DispatchQueue

    init(delay: TimeInterval, delayCallback: @escaping () -> Void, dispatchQueue: DispatchQueue = .main) {
        self.delay = delay
        self.delayCallback = delayCallback
        self.dispatchQueue = dispatchQueue
    }

    public override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            dispatchQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, !self.isCancelled else {
                    self?.asyncFinish()
                    return
                }
                self.delayCallback()
                self.asyncFinish()
            }
        }
    }
}
