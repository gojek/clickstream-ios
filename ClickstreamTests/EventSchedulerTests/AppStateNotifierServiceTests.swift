//
//  AppStateNotifierServiceTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 29/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class AppStateNotifierServiceTests: XCTestCase {

    private let serialQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.appStateNotifierService", qos: .utility)
    
    func testInit_willTerminate() {
        // when
        let state = AppStateNotificationType(with: UIApplication.willTerminateNotification)
        
        // then
        XCTAssertEqual(state, AppStateNotificationType.willTerminate)
    }
    
    func testInit_willResignActive() {
        // when
        let state = AppStateNotificationType(with: UIApplication.willResignActiveNotification)
        
        // then
        XCTAssertEqual(state, AppStateNotificationType.willResignActive)
    }
    
    func testInit_didBecomeActive() {
        // when
        let state = AppStateNotificationType(with: UIApplication.didBecomeActiveNotification)
        
        // then
        XCTAssertEqual(state, AppStateNotificationType.didBecomeActive)
    }
    
    func testInit_default() {
        // when
        let state = AppStateNotificationType(with: Notification.Name(rawValue: "Default"))
        
        // then
        XCTAssertNil(state)
    }
    
    func testInit_didEnterBackground() {
        // when
        let state = AppStateNotificationType(with: UIApplication.didEnterBackgroundNotification)
        
        // then
        XCTAssertEqual(state, AppStateNotificationType.didEnterBackground)
    }
    
    func testInit_willEnterForeground() {
        // when
        let state = AppStateNotificationType(with: UIApplication.willEnterForegroundNotification)
        
        // then
        XCTAssertEqual(state, AppStateNotificationType.willEnterForeground)
    }
    
    func test_respondToNotification() {
        // given
        let expectedState = AppStateNotificationType(with: UIApplication.didEnterBackgroundNotification)
        
        // when
        let appStateNotifierService = DefaultAppStateNotifierService(with: serialQueueMock)
        
        // then
        appStateNotifierService.start { (stateNotification) in
            XCTAssertEqual(stateNotification, expectedState)
        }
        
        // Forcefully fire notification
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func test_stop_appStateNotifierService() {
        // when
        var expectedState = AppStateNotificationType(with: UIApplication.willTerminateNotification)
        
        // when
        let appStateNotifierService = DefaultAppStateNotifierService(with: serialQueueMock)
        
        appStateNotifierService.start { (stateNotification) in
            expectedState = stateNotification
        }
        
        // then
        appStateNotifierService.stop()
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        XCTAssertEqual(expectedState, AppStateNotificationType.willTerminate) // Expected state won't change after notification is fired, since we have called stop()
    }
}
