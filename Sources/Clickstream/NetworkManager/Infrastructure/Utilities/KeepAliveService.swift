//
//  KeepAliveService.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 22/10/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

typealias KeepAliveCallback = (()->())

protocol KeepAliveServiceInputs {
    func start(with subscriber: @escaping KeepAliveCallback)
    func stop()
}

protocol KeepAliveServiceOutputs { }

protocol KeepAliveService: KeepAliveServiceInputs, KeepAliveServiceOutputs { }

final class DefaultKeepAliveServiceWithSafeTimer: KeepAliveService {
    
    private let performQueue: SerialQueue
    private let duration: TimeInterval
    private let reachability: NetworkReachability
    
    private var timer: RepeatingTimer?
    private var subscriber: KeepAliveCallback?

    init(with performOnQueue: SerialQueue,
         duration: TimeInterval,
         reachability: NetworkReachability) {
        self.performQueue = performOnQueue
        self.duration = duration
        self.reachability = reachability
        self.makeTimer()
    }
    
    func start(with subscriber: @escaping KeepAliveCallback) {
        stop()
        if Clickstream.timerCrashFixFlag {
            timer?.suspend()
        } else {
            timer?.resume()
        }
        self.subscriber = subscriber
    }
    
    @discardableResult
    private func makeTimer() -> RepeatingTimer? {
        if Clickstream.timerCrashFixFlag {
            let timerDuration = duration*reachability.connectionRetryCoefficient
            RepeatingTimer.shared.timeInterval = timerDuration
            self.timer = RepeatingTimer.shared
            timer?.eventHandler = { [weak self] in
                guard let checkedSelf = self else { return }
                checkedSelf.performQueue.async {
                    checkedSelf.subscriber?()
                }
            }
            return timer
        } else {
            let timerDuration = duration*reachability.connectionRetryCoefficient
            self.timer = RepeatingTimer(timeInterval: timerDuration)
            timer?.eventHandler = { [weak self] in
                guard let checkedSelf = self else { return }
                checkedSelf.performQueue.async {
                    checkedSelf.subscriber?()
                }
            }
            return timer
        }
    }
    
    func stop() {
        if Clickstream.timerCrashFixFlag {
            timer?.resume()
        } else {
            timer?.suspend()
        }

    }
}
