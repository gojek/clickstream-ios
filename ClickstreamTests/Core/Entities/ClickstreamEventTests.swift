//
//  ClickstreamEventTests.swift
//  ClickstreamTests
//
//  Created by Luqman Fauzi on 30/01/26.
//  Copyright © 2026 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest
import SwiftProtobuf

class ClickstreamEventTests: XCTestCase {
    
    func testEventInitialization() {
        let guid = UUID().uuidString
        let timestamp = Date()
        let message: Message? = nil
        let eventName = "test.event.name"
        let eventData = "test data".data(using: .utf8)!
        let csEventName = "TestEvent"
        let product = "TestProduct"
        
        let event = ClickstreamEvent(
            guid: guid,
            timeStamp: timestamp,
            message: message,
            eventName: eventName,
            eventData: eventData,
            csEventName: csEventName,
            product: product
        )
        
        XCTAssertEqual(event.guid, guid)
        XCTAssertEqual(event.timeStamp, timestamp)
        XCTAssertNil(event.message)
        XCTAssertEqual(event.eventName, eventName)
        XCTAssertEqual(event.eventData, eventData)
        XCTAssertEqual(event.csEventName, csEventName)
        XCTAssertEqual(event.product, product)
    }
    
    func testEventInitializationWithoutOptionalFields() {
        let guid = UUID().uuidString
        let timestamp = Date()
        let eventName = "test.event"
        let eventData = Data()
        let product = "Product"
        
        let event = ClickstreamEvent(
            guid: guid,
            timeStamp: timestamp,
            message: nil,
            eventName: eventName,
            eventData: eventData,
            product: product
        )
        
        XCTAssertEqual(event.guid, guid)
        XCTAssertEqual(event.timeStamp, timestamp)
        XCTAssertNil(event.message)
        XCTAssertEqual(event.eventName, eventName)
        XCTAssertEqual(event.eventData, eventData)
        XCTAssertNil(event.csEventName)
        XCTAssertEqual(event.product, product)
    }
    
    func testMessageNameWithNilMessage() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: nil,
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        XCTAssertEqual(event.messageName, "")
    }
    
    func testMessageNameWithMessage() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        XCTAssertEqual(event.messageName, "odpf.raccoon.Event")
    }
    
    func testShouldTrackOnCourierWithCourierDisabled() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isCourierEnabled: false,
            courierEventTypes: [],
            courierExclusiveEventTypes: []
        )
        
        XCTAssertFalse(event.shouldTrackOnCourier(isUserLoggedIn: true, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnCourierWithUserNotLoggedInAndPreAuthDisabled() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isCourierEnabled: true,
            isCourierPreAuthEnabled: false,
            courierEventTypes: [],
            courierExclusiveEventTypes: []
        )
        
        XCTAssertFalse(event.shouldTrackOnCourier(isUserLoggedIn: false, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnCourierWithUserNotLoggedInAndPreAuthEnabled() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            isCourierEnabled: true,
            isCourierPreAuthEnabled: true,
            courierEventTypes: [],
            courierExclusiveEventTypes: []
        )
        
        XCTAssertTrue(event.shouldTrackOnCourier(isUserLoggedIn: false, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnCourierWithWebsocketDisabled() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: false,
            isCourierEnabled: true,
            courierEventTypes: [],
            courierExclusiveEventTypes: []
        )
        
        XCTAssertTrue(event.shouldTrackOnCourier(isUserLoggedIn: true, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnCourierWithWebsocketEnabledAndNotWhitelisted() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            isCourierEnabled: true,
            courierEventTypes: [],
            courierExclusiveEventTypes: []
        )
        
        XCTAssertFalse(event.shouldTrackOnCourier(isUserLoggedIn: true, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnCourierWithWebsocketEnabledAndCourierWhitelisted() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            isCourierEnabled: true,
            courierEventTypes: ["odpf.raccoon.Event"],
            courierExclusiveEventTypes: []
        )
        
        XCTAssertTrue(event.shouldTrackOnCourier(isUserLoggedIn: true, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnCourierWithWebsocketEnabledAndCourierExclusive() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isWebsocketEnabled: true,
            isCourierEnabled: true,
            courierEventTypes: [],
            courierExclusiveEventTypes: ["odpf.raccoon.Event"]
        )
        
        XCTAssertTrue(event.shouldTrackOnCourier(isUserLoggedIn: true, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnWebsocketWithCourierDisabled() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isCourierEnabled: false,
            courierExclusiveEventTypes: []
        )
        
        XCTAssertTrue(event.shouldTrackOnWebsocket(isUserLoggedIn: true, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnWebsocketWithUserNotLoggedInAndPreAuthDisabled() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isCourierEnabled: true,
            isCourierPreAuthEnabled: false,
            courierExclusiveEventTypes: ["odpf.raccoon.Event"]
        )
        
        XCTAssertTrue(event.shouldTrackOnWebsocket(isUserLoggedIn: false, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnWebsocketWithUserNotLoggedInAndPreAuthEnabled() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isCourierEnabled: true,
            isCourierPreAuthEnabled: true,
            courierExclusiveEventTypes: ["odpf.raccoon.Event"]
        )
        
        XCTAssertFalse(event.shouldTrackOnWebsocket(isUserLoggedIn: false, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnWebsocketWithCourierEnabledUserLoggedInAndExclusiveEvent() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isCourierEnabled: true,
            courierExclusiveEventTypes: ["odpf.raccoon.Event"]
        )
        
        XCTAssertFalse(event.shouldTrackOnWebsocket(isUserLoggedIn: true, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnWebsocketWithCourierEnabledAndNotExclusive() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isCourierEnabled: true,
            courierExclusiveEventTypes: []
        )
        
        XCTAssertTrue(event.shouldTrackOnWebsocket(isUserLoggedIn: true, networkOptions: networkOptions))
    }
    
    func testShouldTrackOnWebsocketWithDifferentMessageName() {
        let event = ClickstreamEvent(
            guid: "test-guid",
            timeStamp: Date(),
            message: Odpf_Raccoon_Event(),
            eventName: "test.event",
            eventData: Data(),
            product: "Product"
        )
        
        let networkOptions = ClickstreamNetworkOptions(
            isCourierEnabled: true,
            courierExclusiveEventTypes: ["different.event.Type"]
        )
        
        XCTAssertTrue(event.shouldTrackOnWebsocket(isUserLoggedIn: true, networkOptions: networkOptions))
    }
    
    func testEventWithEmptyStrings() {
        let event = ClickstreamEvent(
            guid: "",
            timeStamp: Date(),
            message: nil,
            eventName: "",
            eventData: Data(),
            product: ""
        )
        
        XCTAssertTrue(event.guid.isEmpty)
        XCTAssertTrue(event.eventName.isEmpty)
        XCTAssertTrue(event.product.isEmpty)
        XCTAssertTrue(event.eventData.isEmpty)
    }
}
