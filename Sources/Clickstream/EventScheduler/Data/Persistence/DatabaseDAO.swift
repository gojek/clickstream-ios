//
//  DatabaseDAO.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 10/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation
import GRDB

/// The default database DAO. This DAO is the interface for the database.
/// The DAO is always resolved to a type and is specific to a given type.
final class DefaultDatabaseDAO<Object: Codable & DatabasePersistable> {
    
    private let performQueue: SerialQueue
    
    /// The database instance provide during initialisation as a dependency.
    private let database: Database
    
    init(database: Database,
         performOnQueue: SerialQueue) {
        self.performQueue = performOnQueue
        self.database = database
        self.createTable()
    }
    
    /// Responsible to create the table and initiate a legacy daga migration, if needed.
    private func createTable() {
        do {
            try self.database.createTable(Object.self, {
            })
        } catch {
            print("Failed to create table in database with error:- \(error)", .verbose)
        }
    }
    
    /// Use this method to insert the provided object into the db.
    /// - Parameter object: `DatabasePersistable` object to inserted.
    func insert(_ object: Object) {
        performQueue.sync(flags: .barrier) {
            do {
                try database.insert(object)
            } catch {
                print("Failed inserting in database with error:- \(error)", .verbose)
            }
        }
    }
    
    /// Use this method to update the provided object into the db.
    /// - Parameter object: `DatabasePersistable` object to inserted.
    func update(_ object: Object) {
        performQueue.sync(flags: .barrier) {
            do {
                try database.update(object)
            } catch {
                print("Failed updating in database with error:- \(error)", .verbose)
            }
        }
    }
    
    /// Use this method to fetch all objects from a table of the db.
    /// - Returns: An array of `DatabasePersistable` objects.
    func fetchAll() -> [Object]? {
        performQueue.sync(flags: .barrier) {
            do {
                return try database.fetchAll()
            } catch {
                print("Failed to fetch all results:- \(error)", .verbose)
                return nil
            }
        }
    }
    
    /// Use this method to fetch first `n` objects from a table of the db.
    /// - Parameter n: Count of the items to be fetched.
    /// - Returns: An array of `DatabasePersistable` objects.
    func fetchFirst(_ n: Int) -> [Object]? {
        performQueue.sync(flags: .barrier) {
            do {
                return try database.fetchFirst(n)
            } catch {
                print("Failed to fetch first result:- \(error)", .verbose)
                return nil
            }
        }
    }
    
    /// Use this method to fetch the entry which matches the primaryKey value.
    /// - Parameter primaryKeyValue: Value to be matched.
    /// - Returns: An object of `DatabasePersistable` type.
    @discardableResult
    func fetchOne(_ primaryKeyValue: String) -> Object? {
        performQueue.sync(flags: .barrier) {
            do {
                return try database.fetchOne(primaryKeyValue)
            } catch {
                print(error)
                return nil
            }
        }
    }

    /// Use this method to delete all entries from a table.
    /// - Returns: An array of `DatabasePersistable` objects.
    @discardableResult
    func deleteAll() -> [Object]? {
        performQueue.sync(flags: .barrier) {
            do {
                return try database.deleteAll()
            } catch {
                print("Failed to delete all results:- \(error)", .verbose)
                return nil
            }
        }
    }
    
    /// Use this method to delete the entry which matches the primaryKey value.
    /// - Parameter primaryKeyValue: Value to be matched.
    /// - Returns: An object of `DatabasePersistable` type.
    @discardableResult
    func deleteOne(_ primaryKeyValue: String) -> Object? {
        performQueue.sync(flags: .barrier) {
            do {
                return try database.deleteOne(primaryKeyValue)
            } catch {
                print("Failed to delete the result:- \(error)", .verbose)
                return nil
            }
        }
    }
    
    /// Use this method to delete first `n` objects from a table with a `where` clause.
    /// - Parameters:
    ///   - column: GRDB column
    ///   - value: A value for the where clause.
    ///   - n: The count of the objects to be deleted. If `n == 0` delete All.
    /// - Returns: An array of `DatabasePersistable` objects.
    @discardableResult
    func deleteWhere(_ column: Column, value: String, n: Int = 0) -> [Object]? {
        performQueue.sync(flags: .barrier) {
            do {
                return try database.deleteWhere(column, value: value, n: n)
            }  catch {
                print("Failed to delete the result:- \(error)", .verbose)
                return nil
            }
        }
    }
    
    func doesTableExist(with name: String) -> Bool? {
        performQueue.sync(flags: .barrier) {
            do {
                return try database.doesTableExist(with: name)
            } catch {
                print("Failed to fetch the table:- \(error)", .verbose)
                return false
            }
        }
    }
}
