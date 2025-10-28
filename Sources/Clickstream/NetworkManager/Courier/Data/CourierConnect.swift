//
//  CourierConnect.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 13/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

enum CourierConnectCacheType: Int {
    case noop, inMemory, disk
}

struct CourierConnect: Codable {
    let token: String
    let broker: Broker
    let expiryInSec: TimeInterval
    var expiryTimestamp: Date?

    enum CodingKeys: String, CodingKey {
        case expiryInSec = "expiry_in_sec"
        case token, broker, expiryTimestamp
    }

    init(token: String,
         broker: CourierConnect.Broker,
         expiryInSec: TimeInterval,
         expiryTimestamp: Date? = .init()) {

        self.token = token
        self.broker = broker
        self.expiryInSec = expiryInSec
        self.expiryTimestamp = expiryTimestamp
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        token = try values.decodeIfPresent(String.self, forKey: .token) ?? ""
        broker = try values.decodeIfPresent(Broker.self, forKey: .broker) ?? .init(host: "", port: 0)
        expiryInSec = try values.decodeIfPresent(TimeInterval.self, forKey: .expiryInSec) ?? 0
        expiryTimestamp = try values.decodeIfPresent(Date.self, forKey: .expiryTimestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(token, forKey: .token)
        try? container.encode(broker, forKey: .broker)
        try? container.encode(expiryInSec, forKey: .expiryInSec)
        try? container.encode(expiryTimestamp, forKey: .expiryTimestamp)
    }

    struct Broker: Codable {
        let host: String
        let port: Int

        enum CodingKeys: String, CodingKey {
            case host
            case port
        }

        init(host: String, port: Int) {
            self.host = host
            self.port = port
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            host = try values.decodeIfPresent(String.self, forKey: .host) ?? ""
            port = try values.decodeIfPresent(Int.self, forKey: .port) ?? 0
        }
    }
}

