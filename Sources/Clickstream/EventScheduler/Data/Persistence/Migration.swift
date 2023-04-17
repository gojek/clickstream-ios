//
//  Migration.swift
//  ClickStream
//
//  Created by Anirudh Vyas on 17/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation

/// Meant to be run only once!
/// This a fail-safe mechanism which ensures any pending items in the codable cache are migrated before new ones are added.
/// The purpose of this is to migrate all the existing cache items to the database.
struct Migration<Object: Codable & DatabasePersistable> {
        
    init?() {
//        guard Object.doesFileExist() else { return nil }
    }
    
    /// Migrates data from the legacy caching system to the new one.
    /// - Parameters:
    ///   - from: Legacy persistence instance.
    ///   - to: New persistence DAO instance.
    func migrate(_ from: DefaultPersistence<Object>, _ to: DefaultDatabaseDAO<Object>) {
        
        // Fetch and remove from the file system and move to Database and removes the underlying file
        guard let events = from.prefixAndRemoveAll() else { return }
        
        // Add each to database via DAO
        for event in events {
            to.insert(event)
        }
    }
}
