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

final class DefaultKeepAliveService: KeepAliveService {
    
    private let performQueue: SerialQueue
    private let duration: TimeInterval
    private let reachability: NetworkReachability
    
    private var timer: DispatchSourceTimer?
    private var subscriber: KeepAliveCallback?

    init(with performOnQueue: SerialQueue,
         duration: TimeInterval,
         reachability: NetworkReachability) {
        self.performQueue = performOnQueue
        self.duration = duration
        self.reachability = reachability
    }
    
    func start(with subscriber: @escaping KeepAliveCallback) {
        stop()
        makeTimer()?.resume()
        self.subscriber = subscriber
    }
    
    @discardableResult
    private func makeTimer() -> DispatchSourceTimer? {
        guard timer == nil else { return timer }
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: performQueue)
        let timerDuration = duration*reachability.connectionRetryCoefficient
        timer?.schedule(deadline: .now() + timerDuration, repeating: timerDuration)
        timer?.setEventHandler(handler: { [weak self] in
            guard let checkedSelf = self else { return }
            checkedSelf.performQueue.async {
                checkedSelf.subscriber?()
            }
        })
        return timer
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
    }
}

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
        timer?.resume()
        self.subscriber = subscriber
    }
    
    @discardableResult
    private func makeTimer() -> RepeatingTimer? {
        let timerDuration = duration*reachability.connectionRetryCoefficient
        timer = RepeatingTimer(timeInterval: timerDuration)
        timer?.eventHandler = { [weak self] in
            guard let checkedSelf = self else { return }
            checkedSelf.performQueue.async {
                checkedSelf.subscriber?()
            }
        }
        return timer
    }
    
    func stop() {
        timer?.suspend()
    }
}
