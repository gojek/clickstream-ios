//
//  TrackerProtoConvertible.swift
//  Clickstream
//
//  Copyright © 2026 Gojek. All rights reserved.
//

import SwiftProtobuf

protocol TrackerProtoConvertible {
    associatedtype ProtoMessage: Message

    var proto: ProtoMessage { get }
}
