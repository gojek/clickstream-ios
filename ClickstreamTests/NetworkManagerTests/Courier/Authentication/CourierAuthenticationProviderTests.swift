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
    var config: ClickstreamCourierConfig!
    var userCredentials: CourierIdentifiers!
    
    override func setUp() {
        super.setUp()
        mockUserDefaults = UserDefaults(suiteName: "test.courier.auth")
        mockUserDefaults.removePersistentDomain(forName: "test.courier.auth")
        
        config = ClickstreamCourierConfig()
        userCredentials = CourierIdentifiers(
            userIdentifier: "testUser123",
            deviceIdentifier: "device456",
            bundleIdentifier: "com.test.app"
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
            cachingType: .noop,
            userDefaults: mockUserDefaults,
            networkTypeProvider: NetworkType.wifi
        )
        
        XCTAssertNil(provider.cachedAuthResponse)
        XCTAssertEqual(provider.clientId, "testUser123:device456:com.test.app")
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
            cachingType: .disk,
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
            cachingType: .disk,
            userDefaults: mockUserDefaults,
            networkTypeProvider: NetworkType.wifi
        )
        
        XCTAssertNil(provider.cachedAuthResponse)
        XCTAssertNil(mockUserDefaults.data(forKey: "connect_auth_response"))
    }
    
    func testClientIdGeneration() {
        let credentials = CourierIdentifiers(
            userIdentifier: "user123",
            deviceIdentifier: "device456",
            bundleIdentifier: "com.app.test",
            extraIdentifier: "extra789"
        )
        
        let provider = CourierAuthenticationProvider(
            config: config,
            userCredentials: credentials,
            cachingType: .noop,
            userDefaults: mockUserDefaults,
            networkTypeProvider: NetworkType.wifi
        )
        
        XCTAssertEqual(provider.clientId, "user123:extra789:device456:com.app.test")
    }
    
    func testClientIdGenerationWithoutExtra() {
        let provider = CourierAuthenticationProvider(
            config: config,
            userCredentials: userCredentials,
            cachingType: .noop,
            userDefaults: mockUserDefaults,
            networkTypeProvider: NetworkType.wifi
        )
        
        XCTAssertEqual(provider.clientId, "testUser123:device456:com.test.app")
    }
    
    func testClearCachedAuthResponse() {
        let provider = CourierAuthenticationProvider(
            config: config,
            userCredentials: userCredentials,
            cachingType: .disk,
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
    
    func testIsTokenValidWithExpiryDisabled() {
        let pastDate = Date(timeIntervalSinceNow: -3600)
        let courierConnect = CourierConnect(
            token: "test-token",
            broker: CourierConnect.Broker(host: "test.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: pastDate
        )
        
        let isValid = CourierAuthenticationProvider.isTokenValid(
            authResponse: courierConnect,
            cachingType: .disk,
            isTokenCacheExpiryEnabled: false
        )
        
        XCTAssertTrue(isValid)
    }
    
    func testIsTokenValidWithValidToken() {
        let futureDate = Date(timeIntervalSinceNow: 3600)
        let courierConnect = CourierConnect(
            token: "valid-token",
            broker: CourierConnect.Broker(host: "test.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: futureDate
        )
        
        let isValid = CourierAuthenticationProvider.isTokenValid(
            authResponse: courierConnect,
            cachingType: .disk,
            isTokenCacheExpiryEnabled: true
        )
        
        XCTAssertTrue(isValid)
    }
    
    func testIsTokenValidWithExpiredToken() {
        let pastDate = Date(timeIntervalSinceNow: -3600)
        let courierConnect = CourierConnect(
            token: "expired-token",
            broker: CourierConnect.Broker(host: "test.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: pastDate
        )
        
        let isValid = CourierAuthenticationProvider.isTokenValid(
            authResponse: courierConnect,
            cachingType: .disk,
            isTokenCacheExpiryEnabled: true
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
        
        let isValid = CourierAuthenticationProvider.isTokenValid(
            authResponse: courierConnect,
            cachingType: .disk,
            isTokenCacheExpiryEnabled: true
        )
        
        XCTAssertTrue(isValid)
    }
    
    func testIsTokenValidWithInMemoryCaching() {
        let pastDate = Date(timeIntervalSinceNow: -3600)
        let courierConnect = CourierConnect(
            token: "memory-token",
            broker: CourierConnect.Broker(host: "test.com", port: 1883),
            expiryInSec: 3600,
            expiryTimestamp: pastDate
        )
        
        let isValid = CourierAuthenticationProvider.isTokenValid(
            authResponse: courierConnect,
            cachingType: .inMemory,
            isTokenCacheExpiryEnabled: true
        )
        
        XCTAssertTrue(isValid)
    }
}

