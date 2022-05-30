//
//  FileStorable.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 19/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation

protocol FileStorable {
    
    /// Meant to be used only for the deprecated codableCache, meant for migration.
    static var codableCacheKey: String { get }
    
    /// Returns if the file exists or not for the given FileStorable
    static func doesFileExist() -> Bool
}

extension FileStorable where Self: DatabasePersistable {
    
    static func doesFileExist() -> Bool {
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cacheDirectory = cachesDirectory.appendingPathComponent("\(codableCacheKey)/\(codableCacheKey)").path
        return fileManager.fileExists(atPath: cacheDirectory)
    }
}
