//
//  DatabaseHandlerCorruptionTests.swift
//  ClickStreamTests
//
//  Copyright © 2026 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

final class DatabaseHandlerCorruptionTests: XCTestCase {

    private func databaseURL(for qos: DefaultDatabase.QoS) throws -> URL {
        let folderURL = try FileManager()
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("clickstream_\(qos.rawValue)", isDirectory: true)
        try FileManager().createDirectory(at: folderURL, withIntermediateDirectories: true)
        return folderURL.appendingPathComponent("db.sqlite")
    }

    private func removeStore(at dbURL: URL) {
        for suffix in ["", "-wal", "-shm"] {
            let url = URL(fileURLWithPath: dbURL.path + suffix)
            try? FileManager().removeItem(at: url)
        }
    }

    func test_whenStoreIsCorrupt_thenDatabaseIsRecreatedAndUsable() throws {
        let dbURL = try databaseURL(for: .WAL)

        // Simulate a corrupt on-disk store by replacing it with garbage bytes.
        removeStore(at: dbURL)
        let garbage = Data("this is definitely not a sqlite database".utf8)
        try garbage.write(to: dbURL)

        // Initialising must not crash or throw: the corrupt store should be discarded and recreated.
        let database = try DefaultDatabase(qos: .WAL, recoveryEnabled: true)

        let persistence = DefaultDatabaseDAO<Event>(
            database: database,
            performOnQueue: SerialQueue(label: "com.mock.gojek.clickstream.corruption",
                                        qos: .utility,
                                        attributes: .concurrent)
        )

        let event = Event(guid: UUID().uuidString, timestamp: Date(), type: "realTime", eventProtoData: Data())
        persistence.insert(event)

        let events: [Event]? = persistence.fetchAll()
        XCTAssertTrue(events?.map { $0.guid }.contains(event.guid) ?? false,
                      "A fresh, usable database should be available after recovery")
    }

    func test_whenStoreIsHealthy_thenExistingDataIsPreserved() throws {
        // Start from a clean, valid store and insert a record.
        let dbURL = try databaseURL(for: .WAL)
        removeStore(at: dbURL)

        let firstDatabase = try DefaultDatabase(qos: .WAL, recoveryEnabled: true)
        let firstPersistence = DefaultDatabaseDAO<Event>(
            database: firstDatabase,
            performOnQueue: SerialQueue(label: "com.mock.gojek.clickstream.healthy",
                                        qos: .utility,
                                        attributes: .concurrent)
        )
        let event = Event(guid: UUID().uuidString, timestamp: Date(), type: "realTime", eventProtoData: Data())
        firstPersistence.insert(event)

        // Re-opening a healthy store must preserve the data (no false-positive recovery).
        let secondDatabase = try DefaultDatabase(qos: .WAL, recoveryEnabled: true)
        let secondPersistence = DefaultDatabaseDAO<Event>(
            database: secondDatabase,
            performOnQueue: SerialQueue(label: "com.mock.gojek.clickstream.healthy.reopen",
                                        qos: .utility,
                                        attributes: .concurrent)
        )
        let events: [Event]? = secondPersistence.fetchAll()
        XCTAssertTrue(events?.map { $0.guid }.contains(event.guid) ?? false,
                      "Healthy database content must be preserved across re-initialisation")
    }
}
