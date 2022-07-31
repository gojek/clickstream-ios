//
//  NTPClient.swift
//  ClickStreamHost
//
//  Created by Abhijeet Mallick on 23/02/22.
//  Copyright © 2022 Abhijeet Mallick. All rights reserved.
//

import Foundation
import TrueTime

protocol NTPClientProvider {
    func now() -> Date?
}

class DefaultNTPClient: NTPClientProvider {
    private var trueTimeClient: TrueTimeClient?
    private var ntpHost: String!
    
    public static var sharedInstance: DefaultNTPClient?
    
    public static func initialise(isNtpEnabled: Bool, ntpHost: String) -> DefaultNTPClient? {
        
        guard sharedInstance != nil else {
            if isNtpEnabled {
                sharedInstance = DefaultNTPClient(ntpHost: ntpHost)
            }
            return sharedInstance
        }
        return sharedInstance
    }
    
    private init(ntpHost: String) {
        self.ntpHost = ntpHost
        self.trueTimeClient = TrueTimeClient()
        self.start()
    }
    
    private func start() {
        self.trueTimeClient?.start(pool: [ntpHost])
    }
    
    func now(completion: @escaping ((Date?) -> Void)) {
        TrueTimeClient.sharedInstance.fetchIfNeeded { time in
            completion(time.now())
        } failure: { error in
            print("Unable to find time \(error)")
            completion(nil)
        }
    }
    
    func now() -> Date? {
        return self.trueTimeClient?.referenceTime?.now()
    }
}
