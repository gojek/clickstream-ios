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

    private var suspensionCount = 0
    
    private init() { }
    
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()

    var eventHandler: (() -> Void)?

    private enum State {
        case suspended
        case resumed
    }

    private var state: Atomic<State> = Atomic(.suspended)

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

    func resume() {
        if state.value == .resumed {
            return
        }
        suspensionCount -= 1
        state.mutate { state in
            state = .resumed
        }
        if Clickstream.timerCrashFixFlag {
            if suspensionCount > 0 {
                self.timer.resume()
            }
        } else {
            timer.resume()
        }
    }

    func suspend() {
        if state.value == .suspended {
            return
        }
        suspensionCount += 1
        state.mutate { state in
            state = .suspended
        }
        if Clickstream.timerCrashFixFlag {
            if suspensionCount > 0 {
                timer.suspend()
            }
        } else {
            timer.suspend()
        }
    }
}
