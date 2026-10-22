//
//  AppStateNotifierService.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 14/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import UIKit

@_spi(ClickstreamInternal) public enum AppStateNotificationType {
    
    case willTerminate,
    willResignActive,
    didBecomeActive,
    didEnterBackground,
    willEnterForeground
    
    init?(with notificationName: Notification.Name) {
        switch notificationName {
        case UIApplication.willTerminateNotification:
            self = .willTerminate
        case UIApplication.willResignActiveNotification:
            self = .willResignActive
        case UIApplication.didBecomeActiveNotification:
            self = .didBecomeActive
        case UIApplication.didEnterBackgroundNotification:
            self = .didEnterBackground
        case UIApplication.willEnterForegroundNotification:
            self = .willEnterForeground
        default:
            return nil
        }
    }
}

@_spi(ClickstreamInternal) public protocol AppStateNotifierServiceInputs {
    
    /** Starts the notification service with subscriber callback.
        - Parameter subscriber: Subscriber callback.
                                Assign a closure to this to receive callbacks when a status change notification is triggered.
     */
    func start(with subscriber: @escaping (AppStateNotificationType)->())
    
    /// Stops the notifying.
    func stop()
}

@_spi(ClickstreamInternal) public protocol AppStateNotifierServiceOutputs {}

@_spi(ClickstreamInternal) public protocol AppStateNotifierService: AppStateNotifierServiceInputs, AppStateNotifierServiceOutputs  { }

/// The App State Notifier service which notifies the subscriber of the app state changes.
@_spi(ClickstreamInternal) public final class DefaultAppStateNotifierService: AppStateNotifierService {
    
    private var subscriber: ((AppStateNotificationType)->())?
    private let performQueue: SerialQueue

    @_spi(ClickstreamInternal) public init(with performOnQueue: SerialQueue) {
        self.performQueue = performOnQueue
    }
    
    @_spi(ClickstreamInternal) public func start(with subscriber: @escaping (AppStateNotificationType)->()) {
        self.subscriber = subscriber
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(respondToNotification(with:)),
                                       name: UIApplication.willTerminateNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(respondToNotification(with:)),
                                       name: UIApplication.willResignActiveNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(respondToNotification(with:)),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(respondToNotification(with:)),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(respondToNotification(with:)),
                                       name: UIApplication.willEnterForegroundNotification,
                                       object: nil)
    }
    
    @objc private func respondToNotification(with notification: NSNotification) {
        if let state = AppStateNotificationType(with: notification.name) {
            self.performQueue.async { [weak self] in guard let checkedSelf = self else { return }
                checkedSelf.subscriber?(state)
            }
        }
    }
    
    @_spi(ClickstreamInternal) public func stop() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
}
