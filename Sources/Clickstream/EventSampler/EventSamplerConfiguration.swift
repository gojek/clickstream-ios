//
//  EventSamplerconfiguration.swift
//  Clickstream
//
//  Created by Rishab Habbu on 01/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation


// MARK: - Root model
public struct EventSamplerConfiguration: Codable {
    let defaultRate: Int?
    let overrides: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case defaultRate = "default_rate"
        case overrides
    }
    
    init(defaultRate: Int = 0, overrides: [String: Int] = [:]) {
        self.defaultRate = defaultRate
        self.overrides = overrides
    }

    // Custom decoding with safety
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode default_rate safely (fallback = 0)
        self.defaultRate = (try? container.decode(Int.self, forKey: .defaultRate)) ?? EventSamplerConstants.defaultSampleRate

        // Decode overrides safely
        if let overridesDict = try? container.decode([String: Int].self, forKey: .overrides) {
            self.overrides = overridesDict
        } else {
            // If overrides is missing, malformed, or wrong type
            self.overrides = [:]
        }
    }

    // Custom encoder (optional but keeps things clean)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(defaultRate, forKey: .defaultRate)
        let overridesDict = overrides
        try container.encode(overridesDict, forKey: .overrides)
    }
}

