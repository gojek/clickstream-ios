//
//  CourierAuthenticationProviderTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 15/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import CourierCore

class CourierAuthenticationProviderTests: XCTestCase {
    
    var mockUserDefaults: UserDefaults!
    var config: ClickstreamCourierClientConfig!
    var userCredentials: CourierIdentifiers!
    
    override func setUp() {
        super.setUp()
        mockUserDefaults = UserDefaults(suiteName: "test.courier.auth")
        mockUserDefaults.removePersistentDomain(forName: "test.courier.auth")
        
        config = ClickstreamCourierClientConfig()
        userCredentials = CourierIdentifiers(
            userIdentifier: "testUser123",
            deviceIdentifier: "device456",
            bundleIdentifier: "com.test.app",
            extraIdentifier: "test_app",
            authURLRequest: URLRequest(url: .init(string: "some_url")!)
        )
    }
    
    override func tearDown() {
        mockUserDefaults.removePersistentDomain(forName: "test.courier.auth")
        mockUserDefaults = nil
        config = nil
        userCredentials = nil
        super.tearDown()
    }
    
    func testInitWithNoopCaching() {
        let provider = CourierAuthenticationProvider(
            config: config,
            userCredentials: userCredentials,
            userDefaults: mockUserDefaults,
            networkTypeProvider: NetworkType.wifi
        )
        
        XCTAssertNil(provider.cachedAuthResponse)
        XCTAssertEqual(provider.clientId, "device456:test_app:testUser123:com.test.app:clickstream")
    }
    
    func testInitWithDiskCachingValidToken() {
        let futureDate = Date(timeIntervalSinceNow: 3600)
        let courierConnect = CourierConnect(
            token: "valid-token",
            broker: CourierConnect.Broker(host: "test.host.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: futureDate
        )
        
        let data = try! JSONEncoder().encode(courierConnect)
        mockUserDefaults.set(data, forKey: "connect_auth_response")
        
        let provider = CourierAuthenticationProvider(
            config: config,
            userCredentials: userCredentials,
            userDefaults: mockUserDefaults,
            networkTypeProvider: NetworkType.wifi
        )
        
        XCTAssertNotNil(provider.cachedAuthResponse)
        XCTAssertEqual(provider.cachedAuthResponse?.token, "valid-token")
    }
    
    func testInitWithDiskCachingExpiredToken() {
        let pastDate = Date(timeIntervalSinceNow: -3600)
        let courierConnect = CourierConnect(
            token: "expired-token",
            broker: CourierConnect.Broker(host: "test.host.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: pastDate
        )
        
        let data = try! JSONEncoder().encode(courierConnect)
        mockUserDefaults.set(data, forKey: "connect_auth_response")
        
        let provider = CourierAuthenticationProvider(
            config: config,
            userCredentials: userCredentials,
            userDefaults: mockUserDefaults,
            networkTypeProvider: NetworkType.wifi
        )
        
        XCTAssertNotNil(provider.cachedAuthResponse)
        XCTAssertNotNil(mockUserDefaults.data(forKey: "connect_auth_response"))
    }
    
    func testClientIdGeneration() {
        let credentials = CourierIdentifiers(
            userIdentifier: "user123",
            deviceIdentifier: "device456",
            bundleIdentifier: "com.app.test",
            extraIdentifier: "extra789",
            authURLRequest: URLRequest(url: .init(string: "some_url")!)
        )
        
        let provider = CourierAuthenticationProvider(
            config: config,
            userCredentials: credentials,
            userDefaults: mockUserDefaults,
            networkTypeProvider: NetworkType.wifi
        )
        
        XCTAssertEqual(provider.clientId, "device456:extra789:user123:com.app.test:clickstream")
    }
    
    func testClientIdGenerationWithoutExtra() {
        let provider = CourierAuthenticationProvider(
            config: config,
            userCredentials: userCredentials,
            userDefaults: mockUserDefaults,
            networkTypeProvider: NetworkType.wifi
        )
        
        XCTAssertEqual(provider.clientId, "device456:test_app:testUser123:com.test.app:clickstream")
    }
    
    func testClearCachedAuthResponse() {
        let provider = CourierAuthenticationProvider(
            config: config,
            userCredentials: userCredentials,
            userDefaults: mockUserDefaults,
            networkTypeProvider: NetworkType.wifi
        )

        let courierConnect = CourierConnect(
            token: "token-to-clear",
            broker: CourierConnect.Broker(host: "clear.host.com", port: 1883),
            expiryInSec: 3600
        )
        
        let data = try! JSONEncoder().encode(courierConnect)
        mockUserDefaults.set(data, forKey: "connect_auth_response")
        
        provider.clearCachedAuthResponse()
        XCTAssertNil(provider.cachedAuthResponse)
    }
    

    
    func testIsTokenValidWithValidToken() {
        let futureDate = Date(timeIntervalSinceNow: 3599)
        let courierConnect = CourierConnect(
            token: "valid-token",
            broker: CourierConnect.Broker(host: "test.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: futureDate
        )
        
        let isValid = CourierAuthenticationProvider.isCachedTokenValid(
            authResponse: courierConnect
        )
        
        XCTAssertTrue(isValid)
    }
    
    func testIsTokenValidWithExpiredToken() {
        let pastDate = Date(timeIntervalSinceNow: 3601)
        let courierConnect = CourierConnect(
            token: "expired-token",
            broker: CourierConnect.Broker(host: "test.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: pastDate
        )
        
        let isValid = CourierAuthenticationProvider.isCachedTokenValid(
            authResponse: courierConnect
        )
        
        XCTAssertFalse(isValid)
    }
    
    func testIsTokenValidWithNoExpiryTimestamp() {
        let courierConnect = CourierConnect(
            token: "no-expiry-token",
            broker: CourierConnect.Broker(host: "test.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: nil
        )
        
        let isValid = CourierAuthenticationProvider.isCachedTokenValid(
            authResponse: courierConnect
        )
        
        XCTAssertFalse(isValid)
    }
    
    func testIsCachedTokenValidWithThresholdCheck() {
        let expiryMins = 5
        let futureDate = Date(timeIntervalSinceNow: TimeInterval(expiryMins * 60 + 10))
        let courierConnect = CourierConnect(
            token: "threshold-token",
            broker: CourierConnect.Broker(host: "test.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: futureDate
        )
        
        let isValid = CourierAuthenticationProvider.isCachedTokenValid(
            authResponse: courierConnect
        )
        
        XCTAssertTrue(isValid)
    }
    
    func testIsCachedTokenValidBelowThreshold() {
        let expiryMins = 5
        let futureDate = Date(timeIntervalSinceNow: TimeInterval(expiryMins * 60 - 10))
        let courierConnect = CourierConnect(
            token: "below-threshold-token",
            broker: CourierConnect.Broker(host: "test.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: futureDate
        )
        
        let isValid = CourierAuthenticationProvider.isCachedTokenValid(
            authResponse: courierConnect
        )
        
        XCTAssertTrue(isValid)
    }
}

