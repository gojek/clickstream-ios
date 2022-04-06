//
//  TableDefinable.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 19/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import GRDB

typealias VersionIdentifier = String

protocol TableDefinable {
    // pass the table definition to be created. Tables will be specific to each type.
    // i.e. a generic class which resolve to a type. The db will be common.
    static var tableDefinition: (TableDefinition) -> Void { get }
    
    /// Provides description of model.
    static var description: String { get }
    
    /// A unique key which can be used to identify an entry.
    static var primaryKey: String { get }
    
    static var tableMigrations: [(version: VersionIdentifier, alteration: (TableAlteration) -> Void)]?  { get }
}
