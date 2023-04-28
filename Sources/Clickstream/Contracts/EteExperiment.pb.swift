// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: gojek/clickstream/products/events/EteExperiment.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

///platform="ios,android"

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

/// End to End Test suite experiment proto
public struct Gojek_Clickstream_Products_Events_EteExperiment {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Holds the eventName of the event
  public var eventName: String = String()

  /// Note: Auto-filled by the Clickstream SDK, need not be set by the products for every event! If set, will be overridden.
  public var eventTimestamp: SwiftProtobuf.Google_Protobuf_Timestamp {
    get {return _eventTimestamp ?? SwiftProtobuf.Google_Protobuf_Timestamp()}
    set {_eventTimestamp = newValue}
  }
  /// Returns true if `eventTimestamp` has been explicitly set.
  public var hasEventTimestamp: Bool {return self._eventTimestamp != nil}
  /// Clears the value of `eventTimestamp`. Subsequent reads from it will return its default value.
  public mutating func clearEventTimestamp() {self._eventTimestamp = nil}

  /// Note: Auto-filled by the Clickstream SDK, need not be set by the products for every event! If set, will be overridden.
  public var deviceTimestamp: SwiftProtobuf.Google_Protobuf_Timestamp {
    get {return _deviceTimestamp ?? SwiftProtobuf.Google_Protobuf_Timestamp()}
    set {_deviceTimestamp = newValue}
  }
  /// Returns true if `deviceTimestamp` has been explicitly set.
  public var hasDeviceTimestamp: Bool {return self._deviceTimestamp != nil}
  /// Clears the value of `deviceTimestamp`. Subsequent reads from it will return its default value.
  public mutating func clearDeviceTimestamp() {self._deviceTimestamp = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _eventTimestamp: SwiftProtobuf.Google_Protobuf_Timestamp? = nil
  fileprivate var _deviceTimestamp: SwiftProtobuf.Google_Protobuf_Timestamp? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "gojek.clickstream.products.events"

extension Gojek_Clickstream_Products_Events_EteExperiment: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".EteExperiment"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "product"),
    100: .standard(proto: "event_name"),
    101: .standard(proto: "event_timestamp"),
    102: .same(proto: "meta"),
    103: .standard(proto: "device_timestamp"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 100: try decoder.decodeSingularStringField(value: &self.eventName)
      case 101: try decoder.decodeSingularMessageField(value: &self._eventTimestamp)
      case 103: try decoder.decodeSingularMessageField(value: &self._deviceTimestamp)
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.eventName.isEmpty {
      try visitor.visitSingularStringField(value: self.eventName, fieldNumber: 100)
    }
    if let v = self._eventTimestamp {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 101)
    }
    if let v = self._deviceTimestamp {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 103)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Gojek_Clickstream_Products_Events_EteExperiment, rhs: Gojek_Clickstream_Products_Events_EteExperiment) -> Bool {
    if lhs.eventName != rhs.eventName {return false}
    if lhs._eventTimestamp != rhs._eventTimestamp {return false}
    if lhs._deviceTimestamp != rhs._deviceTimestamp {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
