//
//  NetworkReachabilityMock.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 12/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import Foundation


final class NetworkReachabilityMock: NetworkReachability {
    
    var connectionRetryCoefficient: TimeInterval {
        return 1
    }
    
    
    var whenReachable: NetworkReachable?
    var whenUnreachable: NetworkUnreachable?
    
    private let isReachable: Bool
    
    var isAvailable: Bool {
        return isReachable
    }
    
    init(isReachable: Bool) {
        self.isReachable = isReachable
    }
    
    func startNotifier() throws { }
    
    func stopNotifier() { }
    
    func getNetworkType() -> NetworkType {
        return .wifi
    }
}
