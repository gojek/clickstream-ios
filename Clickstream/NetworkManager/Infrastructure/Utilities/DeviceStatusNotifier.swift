//
//  DeviceStatusNotifier.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 27/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import UIKit

protocol DeviceStatusInputs {
    func startTracking()
    func stopTracking()
}

protocol DeviceStatusOutputs {
    typealias BatteryStatus = (_ status: Bool) -> Void
    var onBatteryStatusChanged: BatteryStatus? { get }
    var isDeviceLowOnPower: Bool { get }
}

protocol DeviceStatus: DeviceStatusInputs, DeviceStatusOutputs { }

/// This class handles all the info about device status, give call backs to other class when status is change.
/// Currently only Battery status is being handled
final class DefaultDeviceStatus: DeviceStatus {
    
    private var notificationCenter  = NotificationCenter.default
    private var performQueue: SerialQueue
    /// Enabled/Disable device's battery monitoring
    private var isBatteryMonitoringEnabled: Bool = false {
        didSet {
            UIDevice.current.isBatteryMonitoringEnabled = isBatteryMonitoringEnabled
        }
    }
    
    /// Callback get btattery status changes
    var onBatteryStatusChanged: BatteryStatus?
    
    /// Flag to check whether the device is running on low power or not
    var isDeviceLowOnPower: Bool = false {
        didSet {
            // check if device battery status is changed from oldValue to newValue and if yes then tigger callback
            if oldValue != isDeviceLowOnPower {
                // Perform callback on queue
                performQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.onBatteryStatusChanged?(self.isDeviceLowOnPower)
                }
            }
        }
    }
    
    init(performOnQueue: SerialQueue) {
        self.performQueue = performOnQueue
    }
    
    private func addObservers() {
        notificationCenter.addObserver(self,
                                       selector: #selector(batteryLevelChanged),
                                       name: UIDevice.batteryLevelDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(batteryStateChanged),
                                       name: UIDevice.batteryStateDidChangeNotification,
                                       object: nil)
    }
    
    private func removeObservers() {
        notificationCenter.removeObserver(self)
    }
    
    @objc private func batteryLevelChanged() {
        setIsDeviceOnLowPower()
    }
    
    @objc private func batteryStateChanged() {
        setIsDeviceOnLowPower()
    }
    
    /// Check whether it can perform on low power based on battery level and state conditions
    private func setIsDeviceOnLowPower() {
        let batteryLevelPercent = UIDevice.current.batteryLevel * 100 // Battery level is between 0.0 to 1.0
        let batteryState = UIDevice.current.batteryState
        
        //  If BatteryState is Unplugged/Unknown and BatteryLevel is below 10%
        self.isDeviceLowOnPower = (batteryState == .unplugged || batteryState == .unknown) &&
            batteryLevelPercent < Constants.Defaults.minDeviceBatteryLevel
    }
    
    /// Start battery monitoring and add observer needed to track battery status changes
    func startTracking() {
        self.isBatteryMonitoringEnabled = true
        self.addObservers()
    }
    
    /// Disable battery monitoring anfd remove observers
    func stopTracking() {
        self.isBatteryMonitoringEnabled = false
        self.removeObservers()
    }
}
