//
//  CollectionMapper.swift
//  Launchpad
//
//  Created by Rishav Gupta on 29/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import Foundation

public protocol CollectionMapper {
    var asDictionary: [String: Any] { get }
}

public extension CollectionMapper {
    var asDictionary: [String: Any] {
        let mirror = Mirror(reflecting: self)
        let dict = Dictionary(uniqueKeysWithValues: mirror.children.lazy.map({ (label: String?, value: Any) -> (String, Any)? in
            guard let label = label else { return nil }
            guard label != "unknownFields" else { return nil }

            if let dict = value as? CollectionMapper {
                return (label, dict.asDictionary)
            }
            return (label, value)
        }).compactMap { $0 })
        let asDict = flatten(dictionary: dict)
        return asDict
    }

    func flatten(dictionary: [String: Any]) -> [String: Any] {
        var outputDict = [String: Any]()

        dictionary.forEach { key, value in
            flattenRec(output: &outputDict, keyPath: key, value: value)
        }

        return outputDict
    }

    func flattenRec(output: inout [String: Any], keyPath: String, value: Any) {
        if let dict = value as? [String: Any] {
            dict.forEach { key, value in
                let calculatedKey = "\(keyPath).\(key)".replacingOccurrences(of: "_", with: "").replacingOccurrences(of: "storage.", with: "")
                flattenRec(output: &output, keyPath: calculatedKey, value: value)
            }
        } else {
            output[keyPath] = value
        }
    }
}
