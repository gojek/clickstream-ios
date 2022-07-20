//
//  JSONStringDecoder.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 26/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class JSONStringDecoder {
    
    /** A custom json decoder which takes in a json string and a fallback fileName.
        If the json string decoding produces an exception then the fallback fileName is checked for contents
        - Parameters:
            - json: The JSON string that needs to be decoded.
            - fallbackJson: fallback json string.
     */
    static func decode<T: Decodable>(json: String, fallbackJson: String) -> T? {
        if let data = json.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch {
                print("Loading default configurations",.critical)
                do {
                    if let data = (fallbackJson.data(using: .utf8)) {
                        let result = try decoder.decode(T.self, from: data)
                        return result
                    }
                } catch {
                    print("Error loading local config string: \(fallbackJson)",.critical)
                }
            }
        }
        return nil
    }
}
