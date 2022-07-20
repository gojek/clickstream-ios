//
//  AppVersionChecker.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/09/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation

protocol AppVersionChecker {
    func hasAppVersionChanged() -> Bool
}

final class DefaultAppVersionChecker: AppVersionChecker {
    
    private let kVersionOfLastRun = "com.clickstream.userdefaults.versionOfLastRun"
    
    /// Current Client App Version
    private var currentAppVersion: String?
    /// Last App version synced to the user defaults
    private var savedAppVersion: String?
    
    init(currentAppVersion: String?) {
        self.currentAppVersion = currentAppVersion
        self.savedAppVersion = UserDefaults.standard.object(forKey: kVersionOfLastRun) as? String
    }
    
    /// Returns true if the version of the client app has changed.
    /// - Returns: bool
    func hasAppVersionChanged() -> Bool {
        defer {
            // Save to the user defaults
            UserDefaults.standard.set(currentAppVersion, forKey: kVersionOfLastRun)
            UserDefaults.standard.synchronize()
        }
        
        if savedAppVersion != currentAppVersion {
            return true
        }
        return false
    }
}
