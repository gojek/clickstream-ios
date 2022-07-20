//
//  DatabaseHandler.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 10/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation
import GRDB

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
    
    init(qos: QoS = .utility) throws {
        self.qos = qos
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
        var configuration = Configuration()
        configuration.label = qos.rawValue
        if qos == .WAL {
            dbWriter = try DatabasePool(path: dbURL.path,
                                           configuration: configuration)
        } else {
            dbWriter = try DatabaseQueue(path: dbURL.path,
                                           configuration: configuration)
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
                migrator.registerMigration(migration.version) { db in
                    try db.alter(table: (t.description), body: migration.alteration)
                }
            }
        }
        
        if let dbWriter = dbWriter {
            try migrator.migrate(dbWriter)
        }
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
        try dbWriter?.read { db in
            let objects = try T.fetchAll(db)
            return objects
        }
    }
    
    func fetchFirst<T>(_ n : Int) throws -> [T]? where T: DatabasePersistable {
        try dbWriter?.read { db in
            let objects = try T.limit(n).fetchAll(db)
            return objects
        }
    }
    
    func fetchOne<T>(_ primaryKeyValue: String) throws -> T? where T: DatabasePersistable {
        try dbWriter?.read { db in
            let object = try T.filter(Column(T.primaryKey) == primaryKeyValue).fetchAll(db) // remove from here
            return object.first
        }
    }
    
    func deleteAll<T>() throws -> [T]? where T: DatabasePersistable {
        try dbWriter?.write { db in
            let objects = try T.fetchAll(db)
            _ = try T.deleteAll(db)
            return objects
        }
    }
    
    func deleteOne<T>(_ primaryKeyValue: String) throws -> T? where T: DatabasePersistable {
        try dbWriter?.write { db in
            let object = try T.filter(Column(T.primaryKey) == primaryKeyValue).fetchAll(db)
            try T.filter(Column(T.primaryKey) == primaryKeyValue).deleteAll(db)
            return object.first
        }
    }
    
    func deleteWhere<T>(_ column: Column, value: String, n: Int) throws -> [T]? where T : DatabasePersistable {
        try dbWriter?.write { db in
            let objects = n > 0 ? try T.limit(n).filter(column == value).fetchAll(db) : try T.filter(column == value).fetchAll(db)
            _ = n > 0 ? try T.limit(n).filter(column == value).deleteAll(db) : try T.filter(column == value).deleteAll(db)
            return objects
        }
    }
}
