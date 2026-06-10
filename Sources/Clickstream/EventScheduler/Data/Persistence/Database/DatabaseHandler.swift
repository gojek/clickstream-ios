//
//  DatabaseHandler.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 10/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation
import GRDB

/// Conformance opts a `DatabasePersistable` type into TTL-aware queries by exposing the
/// column that stores its expiration date.
protocol TTLPersistable {
    static var ttlColumn: Column { get }
}

protocol Database {
    
    /// Use this method to create a table in the db, if needed.
    /// - Parameters:
    ///   - t: A TableDefinable type is passed to define the table characteristics.
    ///   - completion: a completion callback for the table creation
    func createTable(_ t: TableDefinable.Type, _ completion: @escaping ()-> Void) throws
        
    /// Use this method to insert a supported type to db.
    /// - Parameter object: a `DatabasePersistable` object to be inserted.
    func insert(_ object: DatabasePersistable) throws
    
    /// Use this method to update a supported type in db.
    /// - Parameter object: a `DatabasePersistable` object to be updated.
    func update(_ object: DatabasePersistable) throws
    
    /// Use this method to fetchAll objects for a type.
    func fetchAll<T: DatabasePersistable>() throws -> [T]?
    
    /// Use this method to fetch first `n` objects from the db.
    /// - Parameter n: The count of the objects to be fetched.
    func fetchFirst<T: DatabasePersistable>(_ n : Int) throws -> [T]?
    
    /// Use this method to fetch one object for a given primaryKeyValue.
    /// - Parameter primaryKeyValue: primary key value
    func fetchOne<T: DatabasePersistable>(_ primaryKeyValue: String) throws -> T?
    
    /// Use this method to delete all the objects from a table in the db.
    func deleteAll<T: DatabasePersistable>() throws -> [T]?
    
    /// Use this method to delete one object for a given primaryKeyValue.
    /// - Parameter primaryKeyValue: primary key value
    func deleteOne<T: DatabasePersistable>(_ primaryKeyValue: String) throws -> T?
    
    /// Use this method to delete first `n` objects from a table with a `where` clause.
    /// - Parameters:
    ///   - column: GRDB column
    ///   - value: A value for the where clause.
    ///   - n: The count of the objects to be deleted.
    func deleteWhere<T: DatabasePersistable>(_ column: Column, value: String, n: Int) throws -> [T]?

    /// Use this method to delete first `n` objects from a table with a `where` clause,
    /// restricted to rows whose TTL column is still in the future (i.e. not expired).
    /// Only applicable to types conforming to `TTLPersistable`.
    /// - Parameters:
    ///   - column: GRDB column for the equality clause.
    ///   - value: A value for the where clause.
    ///   - n: The count of the objects to be deleted. If `n == 0` delete all matches.
    func deleteWhereNotExpired<T: DatabasePersistable & TTLPersistable>(_ column: Column, value: String, n: Int) throws -> [T]?

    /// Use this method to delete objects from a table where the given column's value is
    /// strictly less than the supplied value.
    /// - Parameters:
    ///   - column: GRDB column to evaluate.
    ///   - lessThan: The upper bound (exclusive) for the where clause.
    func deleteWhere<T: DatabasePersistable>(_ column: Column, lessThan value: DatabaseValueConvertible) throws -> [T]?

    /// Suggests whether a table with the name exists or not.
    /// - Parameter name: name of table.
    func doesTableExist(with name: String) throws -> Bool?
}

final class DefaultDatabase: Database {
    
    /// Defines the quality of service for the Database.
    enum QoS: String {
        case utility = "utility"
        /// Choose this qos to open the db in WAL (write-ahead logging) mode.
        case WAL = "wal"
    }
    
    private var dbWriter: DatabaseWriter?
    private var migrator = DatabaseMigrator()
    private let qos: QoS
    private var registeredMigrations: Set<String> = Set()
    
    /// When `true`, the store is integrity-checked on open and recreated if corrupt.
    /// Gated behind a client-supplied feature flag; defaults to `false` to preserve legacy behaviour.
    private let recoveryEnabled: Bool
    
    init(qos: QoS = .utility, recoveryEnabled: Bool = false) throws {
        self.qos = qos
        self.recoveryEnabled = recoveryEnabled
        try prepareDatabase()
    }
    
    private func prepareDatabase() throws {
        
        let fileManager = FileManager()
        let folderURL = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("clickstream_\(qos.rawValue)", isDirectory: true)
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        // Connect to a database on disk
        let dbURL = folderURL.appendingPathComponent("db.sqlite")
        
        guard recoveryEnabled else {
            // Legacy behaviour: open the store directly without integrity validation.
            var configuration = Configuration()
            configuration.label = qos.rawValue
            dbWriter = try open(at: dbURL, configuration: configuration)
            return
        }
        
        do {
            dbWriter = try makeResilientWriter(at: dbURL)
            // Validate the store before any record is read. A corrupt on-disk store would
            // otherwise hand back a bogus blob length while decoding (e.g. `EventRequest.data`),
            // which crashes hard inside `Data` initialisation on a reader connection and cannot
            // be caught with `try?`.
            try verifyIntegrity()
        } catch {
            // The store is unusable/corrupt. Discard it and start fresh so the SDK recovers
            // instead of crash-looping on every read of the bad database.
            print("Clickstream database is corrupt, recreating it. Description: \(error)")
            dbWriter = nil
            try discardDatabaseFiles(at: dbURL)
            dbWriter = try makeResilientWriter(at: dbURL)
            reportDatabaseCorruption()
        }
    }
    
    /// Emits a health event when a corrupt store had to be recreated. The tracker is usually not
    /// ready yet at SDK-initialisation time, so the event is deferred and flushed once the tracker
    /// is available.
    private func reportDatabaseCorruption() {
        #if TRACKER_ENABLED
        if Tracker.debugMode {
            if let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamDBCorrupted,
                                                     reason: FailureReason.db_corrupted.rawValue) {
                Tracker.sharedInstance?.record(event: healthEvent)
            } else {
                Tracker.pendingDatabaseCorruptionRecovery = true
            }
        }
        #endif
    }
    
    /// Opens the on-disk store with the connection type matching the configured `QoS`.
    private func open(at dbURL: URL, configuration: Configuration) throws -> DatabaseWriter {
        if qos == .WAL {
            return try DatabasePool(path: dbURL.path, configuration: configuration)
        } else {
            return try DatabaseQueue(path: dbURL.path, configuration: configuration)
        }
    }
    
    /// Opens the store with a busy timeout so concurrent access waits for held locks instead of
    /// failing immediately with `SQLITE_BUSY`.
    private func makeResilientWriter(at dbURL: URL) throws -> DatabaseWriter {
        var configuration = Configuration()
        configuration.label = qos.rawValue
        configuration.busyMode = .timeout(Constants.Defaults.databaseBusyTimeout)
        return try open(at: dbURL, configuration: configuration)
    }
    
    /// Runs a SQLite integrity check and throws when the store reports corruption.
    private func verifyIntegrity() throws {
        try dbWriter?.read { db in
            let result = try String.fetchOne(db, sql: "PRAGMA quick_check") ?? ""
            guard result.caseInsensitiveCompare("ok") == .orderedSame else {
                throw DatabaseError(resultCode: .SQLITE_CORRUPT,
                                    message: "Integrity check failed: \(result)")
            }
        }
    }
    
    /// Removes the SQLite database file together with its `-wal` and `-shm` side files.
    private func discardDatabaseFiles(at dbURL: URL) throws {
        let fileManager = FileManager()
        for suffix in ["", "-wal", "-shm"] {
            let url = URL(fileURLWithPath: dbURL.path + suffix)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }
    
    func createTable(_ t: TableDefinable.Type, _ completion: @escaping ()-> Void) throws {
        if try doesTableExist(with: t.description) ?? false == false {
            try dbWriter?.write { db in
                try db.create(table: t.description, body: t.tableDefinition)
                completion()
            }
        }
        
        
        // register migrations.
        t.tableMigrations?.forEach { migration in
            if !registeredMigrations.contains(migration.version) {
                registeredMigrations.insert(migration.version)
                let tableName = t.description
                migrator.registerMigration(migration.version) { db in
                    do {
                        try db.alter(table: tableName, body: migration.alteration)
                    } catch let error as DatabaseError where Self.isDuplicateColumn(error) {
                        // The column already exists, either because it is part of the table's
                        // base `tableDefinition` for fresh installs, or because a prior run added
                        // it. Treat the migration as a no-op so the shared migrator records it as
                        // applied and does not abort, which would otherwise skip every migration
                        // registered after it (e.g. `adds_ttl_to_courier_event_table`).
                    }
                }
            }
        }
        
        if let dbWriter = dbWriter {
            try migrator.migrate(dbWriter)
        }
    }

    /// Returns `true` when the error is SQLite's "duplicate column name" failure, raised when a
    /// migration tries to add a column that already exists on the table.
    private static func isDuplicateColumn(_ error: DatabaseError) -> Bool {
        (error.message?.lowercased().contains("duplicate column")) == true
    }
}

extension DefaultDatabase {
    
    func doesTableExist(with name: String) throws -> Bool? {
        try dbWriter?.read { db in
            let doesTableExist = try db.tableExists(name)
            return doesTableExist
        }
    }
    
    func insert(_ object: DatabasePersistable) throws {
        try dbWriter?.write { db in
            try object.insert(db)
        }
    }
    
    func update(_ object: DatabasePersistable) throws {
        try dbWriter?.write { db in
            try object.update(db)
        }
    }
    
    func fetchAll<T>() throws -> [T]? where T: DatabasePersistable {
        try autoreleasepool {
            try dbWriter?.read { db in
                let objects = try T.fetchAll(db)
                return objects
            }
        }
    }
    
    func fetchFirst<T>(_ n : Int) throws -> [T]? where T: DatabasePersistable {
        try autoreleasepool {
            try dbWriter?.read { db in
                let objects = try T.limit(n).fetchAll(db)
                return objects
            }
        }
    }
    
    func fetchOne<T>(_ primaryKeyValue: String) throws -> T? where T: DatabasePersistable {
        try dbWriter?.read { db in
            let object = try T.filter(Column(T.primaryKey) == primaryKeyValue).fetchAll(db) // remove from here
            return object.first
        }
    }
    
    func deleteAll<T>() throws -> [T]? where T: DatabasePersistable {
        try autoreleasepool {
            try dbWriter?.write { db in
                let objects = try T.fetchAll(db)
                _ = try T.deleteAll(db)
                return objects
            }
        }
    }
    
    func deleteOne<T>(_ primaryKeyValue: String) throws -> T? where T: DatabasePersistable {
        try autoreleasepool {
            try dbWriter?.write { db in
                let object = try T.filter(Column(T.primaryKey) == primaryKeyValue).fetchAll(db)
                try T.filter(Column(T.primaryKey) == primaryKeyValue).deleteAll(db)
                return object.first
            }
        }
    }
    
    func deleteWhere<T>(_ column: Column, value: String, n: Int) throws -> [T]? where T : DatabasePersistable {
        try autoreleasepool {
            try dbWriter?.write { db in
                let objects = n > 0 ? try T.limit(n).filter(column == value).fetchAll(db) : try T.filter(column == value).fetchAll(db)
                _ = n > 0 ? try T.limit(n).filter(column == value).deleteAll(db) : try T.filter(column == value).deleteAll(db)
                return objects
            }
        }
    }

    func deleteWhereNotExpired<T>(_ column: Column, value: String, n: Int) throws -> [T]? where T : DatabasePersistable & TTLPersistable {
        try dbWriter?.write { db in
            let baseRequest = T.filter(column == value && T.ttlColumn >= Date())
            let request = n > 0 ? baseRequest.limit(n) : baseRequest
            let objects = try request.fetchAll(db)
            _ = try request.deleteAll(db)
            return objects
        }
    }

    func deleteWhere<T>(_ column: Column, lessThan value: DatabaseValueConvertible) throws -> [T]? where T : DatabasePersistable {
        try dbWriter?.write { db in
            let objects = try T.filter(column < value).fetchAll(db)
            _ = try T.filter(column < value).deleteAll(db)
            return objects
        }
    }
}

