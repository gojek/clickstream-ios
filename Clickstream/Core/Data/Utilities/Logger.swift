//
//  Logger.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 26/08/20.
//  Copyright © 2020 Gojek. All rights reserved.
//
//  Referenced from: https://medium.com/@sauvik_dolui/developing-a-tiny-logger-in-swift-7221751628e6

import Foundation

/// Wrapping Swift.print() within DEBUG flag
///
/// - Parameter object: The object which is to be logged
///
func print(_ object: Any, _ level: Logger.LogLevel = .verbose) {
    
    if level >= Logger.logLevel {
        Swift.print("Clickstream [💬] \(Date().toString()) : \(object)")
    }
}

public class Logger {
    
    static var dateFormat = "yyyy-MM-dd hh:mm:ssSSS"
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    fileprivate static var _logLevel: LogLevel = .critical
    static var logLevel: LogLevel {
        get {
            return _logLevel
        } set {
            _logLevel = newValue
        }
    }
    
    /// Defines the various log levels of the SDK.
    public enum LogLevel: Int, Comparable, CaseIterable {
        case verbose = 0
        case critical
        case none
        
        public static func < (lhs: Logger.LogLevel, rhs: Logger.LogLevel) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
}

extension Date {
    func toString() -> String {
        return Logger.dateFormatter.string(from: self as Date)
    }
}
