//
//  EventRequestPersistable.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 14/11/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol EventRequestPersistable: Codable, Equatable {
    var guid: String { get }
    var data: Data? { get set }
    var timeStamp: Date { get set }
    var retriesMade: Int { get set }
    var createdTimestamp: Date? { get }
    var eventType: Constants.EventType? { get }
    var isInternal: Bool? { get }
    var eventCount: Int { get }
}

extension EventRequestPersistable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.guid == rhs.guid
    }
}

extension EventRequestPersistable {

    mutating func bumpRetriesMade() {
        retriesMade = (retriesMade + 1)
    }
    
    mutating func resetRetries() {
        retriesMade = 0
    }

    mutating func refreshCachingTimeStamp() {
        self.timeStamp = Date()
    }

    mutating func refreshBatchSentTimeStamp() throws {
        guard let data, !data.isEmpty else {
            return
        }

        var requestProto = try Odpf_Raccoon_EventRequest(serializedBytes: data)
        requestProto.sentTime = Google_Protobuf_Timestamp(date: Date())

        do {
            self.data = try requestProto.serializedData()
        } catch is BinaryEncodingError {
            // Fallback to partial encoding for malformed payloads that fail full validation.
            self.data = try requestProto.serializedData(partial: true)
        }
    }
}
