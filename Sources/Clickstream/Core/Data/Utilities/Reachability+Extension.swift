//
//  Reachability+Extension.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 09/09/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import Reachability
import CoreTelephony

enum NetworkType: Equatable {
    case unknown
    case noConnection
    case wifi
    case wwan2g
    case wwan3g
    case wwan4g
    case wwan5g
    case unknownTechnology(name: String)
    
    var trackingId: String {
        switch self {
        case .unknown:                      return "Unknown"
        case .noConnection:                 return "No Connection"
        case .wifi:                         return "Wifi"
        case .wwan2g:                       return "2G"
        case .wwan3g:                       return "3G"
        case .wwan4g:                       return "4G"
        case .wwan5g:                       return "5G"
        case .unknownTechnology(let name):  return "Unknown Technology: \"\(name)\""
        }
    }
}

extension Reachability {    
    static func getNetworkType() -> NetworkType {
        do {
            let reachability: Reachability = try Reachability()
            try reachability.startNotifier()
            switch reachability.connection {
            case .unavailable, .none:
                return .noConnection
            case .wifi:
                return .wifi
            case .cellular:
                return Reachability.getWWANNetworkType()
            }
        } catch {
            return .unknown
        }
    }
    
    internal static func getWWANNetworkType() -> NetworkType {
        var _currentRadioAccessTechnology: String? = nil
        if let accessTechnology = CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology?.values.first{
            _currentRadioAccessTechnology = accessTechnology
        }

        guard let currentRadioAccessTechnology = _currentRadioAccessTechnology else { return .unknown }
        
        if #available(iOS 14.1, *) {
            if currentRadioAccessTechnology == CTRadioAccessTechnologyNRNSA || currentRadioAccessTechnology == CTRadioAccessTechnologyNR{
                return .wwan5g
            }
        }
        switch currentRadioAccessTechnology {
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            return .wwan2g
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            return .wwan3g
        case CTRadioAccessTechnologyLTE:
            return .wwan4g
        default:
            return .unknownTechnology(name: currentRadioAccessTechnology)
        }
    }
}
