//
//  NetworkReachability.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 12/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import Reachability

typealias NetworkReachable = (NetworkReachability) -> ()
typealias NetworkUnreachable = (NetworkReachability) -> ()

protocol NetworkReachabilityInputs {
    var whenReachable: NetworkReachable? { get set }
    var whenUnreachable: NetworkUnreachable? { get set }
    func startNotifier() throws
    func stopNotifier()
}

protocol NetworkReachabilityOutputs {
    var isAvailable: Bool { get }
    func getNetworkType() -> NetworkType
    var connectionRetryCoefficient: TimeInterval { get }
}

protocol NetworkReachability: NetworkReachabilityInputs, NetworkReachabilityOutputs { }

final class DefaultNetworkReachability: NetworkReachability {
    
    var whenReachable: NetworkReachable?
    var whenUnreachable: NetworkUnreachable?
    
    private let reachability: Reachability
    
    init(with targetQueue: SerialQueue) throws {
        
        reachability = try Reachability(queueQoS: .utility,
                                        targetQueue: targetQueue,
                                        notificationQueue: targetQueue)
        reachability.whenReachable = { [weak self] _ in guard let checkedSelf = self else { return }
            checkedSelf.triggerStatusUpdateCallbacks()
        }
        reachability.whenUnreachable = { [weak self] _ in guard let checkedSelf = self else { return }
            checkedSelf.triggerStatusUpdateCallbacks()
        }
    }
    
    private func triggerStatusUpdateCallbacks() {
        reachability.connection != .unavailable ? whenReachable?(self) : whenUnreachable?(self)
    }
}

extension DefaultNetworkReachability {
    var isAvailable: Bool {
        reachability.connection != .unavailable
    }
    
    func getNetworkType() -> NetworkType {
        return Reachability.getNetworkType()
    }
}

extension DefaultNetworkReachability {
    
    func startNotifier() throws {
        try reachability.startNotifier()
    }
    
    func stopNotifier() {
        reachability.stopNotifier()
    }
}

extension DefaultNetworkReachability {
    
    var connectionRetryCoefficient: TimeInterval {
        get {
            let networkType = Reachability.getNetworkType()
            switch networkType {
            case .wifi:
                return 1
            case .wwan4g:
                return 1.3
            case .wwan3g:
                return 1.6
            case .wwan2g:
                return 2.2
            default:
                return 1
            }
        }
    }
}
