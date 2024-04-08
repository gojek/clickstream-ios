//
//  DatabaseDAOTests.swift
//  ClickStreamTests
//
//  Created by Anirudh Vyas on 25/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class DatabaseDAOTests: XCTestCase {
    
    private let database = try! DefaultDatabase(qos: .WAL)
    private let dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network",
                                          qos: .utility,
                                          attributes: .concurrent)
    private var persistence: DefaultDatabaseDAO<Event>!
    
    override func setUp() {
        persistence = DefaultDatabaseDAO<Event>(database: database,
                                                    performOnQueue: dbQueueMock)
    }
    
    func test_whenDAOIsInitialised_thenTableMustBeCreated() {
        
        let expectation = self.expectation(description: "Table exists")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let tableExists = try! self.persistence.doesTableExist(with: Event.description)
            XCTAssertTrue(tableExists!, "Table Exists")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func test_whenInsertOnTheDAOIsCalled_thenTheObjectMustBeAddedToDatabase() {
        let event = Event(guid: UUID().uuidString, timestamp: Date(), type: "realTime", eventProtoData: Data())
        
        persistence.insert(event)
        if let events: [Event] = self.persistence.fetchAll() {
            XCTAssertTrue(events.map { $0.guid }.contains(event.guid), "Event exists")
        }
    }
}
