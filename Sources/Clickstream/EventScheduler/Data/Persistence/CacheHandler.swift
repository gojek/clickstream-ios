//
//  CacheHandler.swift
//  ClickStream
//
//  Created by Abhijeet Mallick on 18/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class DefaultPersistence<T: Codable & DatabasePersistable> {
    typealias Object = T
    
    private let cache: CodableCache<[Object]>
    private let queue: DispatchQueue
    
    init(key: String) {
        self.cache = CodableCache<[Object]>(key: key)
        queue = DispatchQueue(label: "com.clickstream.cache.queue.\(key)", attributes: .concurrent)
    }
    
    private func getAll() -> [Object]? {
        queue.sync(flags: .barrier) {
            self.cache.get()
        }
    }
    
    /// remove object from cache
    private func removeAll() {
        queue.sync(flags: .barrier) {
            try? self.cache.clear()
        }
    }

    /// Get all objects store in cache, and remove it
    /// - Returns: [Objects]
    func prefixAndRemoveAll() -> [Object]? {
        defer {
            self.removeAll()
        }
        return self.getAll()
    }
}
