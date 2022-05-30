//
//  DatabasePersistable.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 19/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import GRDB

/// Any object conforming to this protocol can be persisted on the db.
protocol DatabasePersistable: FetchableRecord, PersistableRecord, TableDefinable, FileStorable {}
