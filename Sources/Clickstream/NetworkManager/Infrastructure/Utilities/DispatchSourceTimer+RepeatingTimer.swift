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
    private var timeInterval: TimeInterval = 0
    private var newTimer: DispatchSourceTimer?
    
    private init() { }
    
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    
    func setup(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
        setupTimer()
    }
    
    private func setupTimer() {
        guard timeInterval > 0 else { return }
        newTimer = DispatchSource.makeTimerSource()
        newTimer?.schedule(deadline: .now() + timeInterval, repeating: timeInterval)
        newTimer?.setEventHandler { [weak self] in
            self?.eventHandler?()
        }
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
        if Clickstream.timerCrashFixFlag {
            newTimer?.setEventHandler {}
            newTimer?.cancel()
        } else {
            timer.setEventHandler {}
            timer.cancel()
        }
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
        if Clickstream.timerCrashFixFlag {
            newTimer?.resume()
        } else {
            timer.resume()
        }
    }

    func suspend() {
        if state.value == .suspended {
            return
        }
        state.mutate { state in
            state = .suspended
        }
        
        if Clickstream.timerCrashFixFlag {
            newTimer?.suspend()
        } else {
            timer.suspend()
        }
    }
}
