//
//  Constants.swift
//  Example
//
//  Created by Rishav Gupta on 14/04/23.
//  Copyright © 2023 Gojek. All rights reserved.
//

import Foundation

struct Constants {
    /// Email and click count used for ETE Test Suite
    static var email = ""
    static var clickCount = 10
    
    private static func getContentsOfFile(name: String, type: String) -> String {
        if let filepath = Bundle.main.path(forResource: name, ofType: type) {
            do {
                let contents = try String(contentsOfFile: filepath)
                return contents
            } catch {
                return ""
            }
        } else {
            return ""
        }
    }
    
    static func testConfigs() -> [String: Any]? {
        let config = getContentsOfFile(name: "testConfigs", type: "txt").replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\n", with: "", options: NSString.CompareOptions.literal, range: nil)
        return convertToDictionary(text: config)
    }
    
    static func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
