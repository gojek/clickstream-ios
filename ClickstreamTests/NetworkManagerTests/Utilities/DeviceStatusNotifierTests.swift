//
//  DeviceStatusNotifierTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 29/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class DeviceStatusNotifierTests: XCTestCase {
    
    private let serialQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.deviceStatus", qos: .utility)
    
    func testIsDeviceLowOnPower() {
        // given
        let deviceStatus = DefaultDeviceStatus(performOnQueue: serialQueueMock)
        
        // when
        deviceStatus.isDeviceLowOnPower = true
        deviceStatus.stopTracking()
        
        // then
        XCTAssertTrue(deviceStatus.isDeviceLowOnPower)
        
    }
    
    func testBatteryLevelChanged() {
        // given
        let deviceStatus = DefaultDeviceStatus(performOnQueue: serialQueueMock)
        deviceStatus.startTracking()
        deviceStatus.self.isDeviceLowOnPower = true
        
        // when
        NotificationCenter.default.post(name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        
        // then
        deviceStatus.onBatteryStatusChanged = { isLowOnPower in
            XCTAssertFalse(isLowOnPower)
        }
    }
    
    func testBatteryStateChanged() {
        // given
        let deviceStatus = DefaultDeviceStatus(performOnQueue: serialQueueMock)
        deviceStatus.startTracking()
        deviceStatus.self.isDeviceLowOnPower = true
        
        // when
        NotificationCenter.default.post(name: UIDevice.batteryStateDidChangeNotification, object: nil)
        
        // then
        deviceStatus.onBatteryStatusChanged = { isLowOnPower in
            XCTAssertFalse(isLowOnPower)
        }        
    }
}
