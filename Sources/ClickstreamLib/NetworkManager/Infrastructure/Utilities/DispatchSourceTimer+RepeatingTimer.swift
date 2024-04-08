//
//  DispatchSourceTimer+RepeatingTimer.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 12/12/21.
//  Copyright © 2021 Gojek. All rights reserved.
//
// Reference: https://medium.com/over-engineering/a-background-repeating-timer-in-swift-412cecfd2ef9

import Foundation

/// RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
/// crashes that occur from calling resume multiple times on a timer that is
/// already resumed (noted by https://github.com/SiftScience/sift-ios/issues/52)
class RepeatingTimer {

    static let shared = RepeatingTimer()
    
    var timeInterval: TimeInterval = 0
    
    private init() { }
    
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    
    private lazy var timer: DispatchSourceTimer = { [weak self] in
        let t = DispatchSource.makeTimerSource()
        guard let checkedSelf = self else { return t }
        t.schedule(deadline: .now() + (checkedSelf.timeInterval), repeating: checkedSelf.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()

    var eventHandler: (() -> Void)?

    private enum State {
        case notInitialized
        case suspended
        case resumed
    }

    private var state: Atomic<State> = Clickstream.timerCrashFixFlag ? Atomic(.notInitialized) : Atomic(.suspended)

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }

    // decrements an internal suspension count.
    func resume() {
        if Clickstream.timerCrashFixFlag {
            if state.value == .resumed || state.value == .notInitialized {
                return
            }
        } else {
            if state.value == .resumed {
                return
            }
        }
        state.mutate { state in
            state = .resumed
        }
        timer.resume()

    }

    // increments an internal suspension count.
    func suspend() {
        if state.value == .suspended {
            return
        }
        state.mutate { state in
            state = .suspended
        }
        timer.suspend()
    }
}
