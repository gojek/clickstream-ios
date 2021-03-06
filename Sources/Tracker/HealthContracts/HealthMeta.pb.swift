// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: gojek/clickstream/internal/HealthMeta.proto
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

struct Gojek_Clickstream_Internal_HealthMeta {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var eventGuid: String = String()

  var location: Gojek_Clickstream_Internal_HealthMeta.Location {
    get {return _location ?? Gojek_Clickstream_Internal_HealthMeta.Location()}
    set {_location = newValue}
  }
  /// Returns true if `location` has been explicitly set.
  var hasLocation: Bool {return self._location != nil}
  /// Clears the value of `location`. Subsequent reads from it will return its default value.
  mutating func clearLocation() {self._location = nil}

  var customer: Gojek_Clickstream_Internal_HealthMeta.Customer {
    get {return _customer ?? Gojek_Clickstream_Internal_HealthMeta.Customer()}
    set {_customer = newValue}
  }
  /// Returns true if `customer` has been explicitly set.
  var hasCustomer: Bool {return self._customer != nil}
  /// Clears the value of `customer`. Subsequent reads from it will return its default value.
  mutating func clearCustomer() {self._customer = nil}

  var device: Gojek_Clickstream_Internal_HealthMeta.Device {
    get {return _device ?? Gojek_Clickstream_Internal_HealthMeta.Device()}
    set {_device = newValue}
  }
  /// Returns true if `device` has been explicitly set.
  var hasDevice: Bool {return self._device != nil}
  /// Clears the value of `device`. Subsequent reads from it will return its default value.
  mutating func clearDevice() {self._device = nil}

  var session: Gojek_Clickstream_Internal_HealthMeta.Session {
    get {return _session ?? Gojek_Clickstream_Internal_HealthMeta.Session()}
    set {_session = newValue}
  }
  /// Returns true if `session` has been explicitly set.
  var hasSession: Bool {return self._session != nil}
  /// Clears the value of `session`. Subsequent reads from it will return its default value.
  mutating func clearSession() {self._session = nil}

  var app: Gojek_Clickstream_Internal_HealthMeta.App {
    get {return _app ?? Gojek_Clickstream_Internal_HealthMeta.App()}
    set {_app = newValue}
  }
  /// Returns true if `app` has been explicitly set.
  var hasApp: Bool {return self._app != nil}
  /// Clears the value of `app`. Subsequent reads from it will return its default value.
  mutating func clearApp() {self._app = nil}

  var network: Gojek_Clickstream_Internal_HealthMeta.Network {
    get {return _network ?? Gojek_Clickstream_Internal_HealthMeta.Network()}
    set {_network = newValue}
  }
  /// Returns true if `network` has been explicitly set.
  var hasNetwork: Bool {return self._network != nil}
  /// Clears the value of `network`. Subsequent reads from it will return its default value.
  mutating func clearNetwork() {self._network = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  enum NetworkType: SwiftProtobuf.Enum {
    typealias RawValue = Int
    case unspecified // = 0
    case noConnection // = 1
    case wifi // = 2
    case wwan2G // = 3
    case wwan3G // = 4
    case wwan4G // = 5
    case UNRECOGNIZED(Int)

    init() {
      self = .unspecified
    }

    init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .unspecified
      case 1: self = .noConnection
      case 2: self = .wifi
      case 3: self = .wwan2G
      case 4: self = .wwan3G
      case 5: self = .wwan4G
      default: self = .UNRECOGNIZED(rawValue)
      }
    }

    var rawValue: Int {
      switch self {
      case .unspecified: return 0
      case .noConnection: return 1
      case .wifi: return 2
      case .wwan2G: return 3
      case .wwan3G: return 4
      case .wwan4G: return 5
      case .UNRECOGNIZED(let i): return i
      }
    }

  }

  struct App {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    var version: String = String()

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
  }

  struct Customer {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    var signedUpCountry: String = String()

    var currentCountry: String = String()

    var identity: Int32 = 0

    var email: String = String()

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
  }

  struct Device {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    var operatingSystem: String = String()

    var operatingSystemVersion: String = String()

    var deviceMake: String = String()

    var deviceModel: String = String()

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
  }

  struct Location {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    var latitude: Double = 0

    var longitude: Double = 0

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
  }

  struct Session {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    var sessionID: String = String()

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
  }

  struct Network {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    var type: Gojek_Clickstream_Internal_HealthMeta.NetworkType = .unspecified

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
  }

  init() {}

  fileprivate var _location: Gojek_Clickstream_Internal_HealthMeta.Location? = nil
  fileprivate var _customer: Gojek_Clickstream_Internal_HealthMeta.Customer? = nil
  fileprivate var _device: Gojek_Clickstream_Internal_HealthMeta.Device? = nil
  fileprivate var _session: Gojek_Clickstream_Internal_HealthMeta.Session? = nil
  fileprivate var _app: Gojek_Clickstream_Internal_HealthMeta.App? = nil
  fileprivate var _network: Gojek_Clickstream_Internal_HealthMeta.Network? = nil
}

#if swift(>=4.2)

extension Gojek_Clickstream_Internal_HealthMeta.NetworkType: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static var allCases: [Gojek_Clickstream_Internal_HealthMeta.NetworkType] = [
    .unspecified,
    .noConnection,
    .wifi,
    .wwan2G,
    .wwan3G,
    .wwan4G,
  ]
}

#endif  // swift(>=4.2)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "gojek.clickstream.internal"

extension Gojek_Clickstream_Internal_HealthMeta: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".HealthMeta"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "event_guid"),
    4: .same(proto: "location"),
    5: .same(proto: "customer"),
    6: .same(proto: "device"),
    7: .same(proto: "session"),
    8: .same(proto: "app"),
    9: .same(proto: "network"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularStringField(value: &self.eventGuid)
      case 4: try decoder.decodeSingularMessageField(value: &self._location)
      case 5: try decoder.decodeSingularMessageField(value: &self._customer)
      case 6: try decoder.decodeSingularMessageField(value: &self._device)
      case 7: try decoder.decodeSingularMessageField(value: &self._session)
      case 8: try decoder.decodeSingularMessageField(value: &self._app)
      case 9: try decoder.decodeSingularMessageField(value: &self._network)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.eventGuid.isEmpty {
      try visitor.visitSingularStringField(value: self.eventGuid, fieldNumber: 1)
    }
    if let v = self._location {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
    }
    if let v = self._customer {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
    }
    if let v = self._device {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 6)
    }
    if let v = self._session {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 7)
    }
    if let v = self._app {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 8)
    }
    if let v = self._network {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 9)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Gojek_Clickstream_Internal_HealthMeta, rhs: Gojek_Clickstream_Internal_HealthMeta) -> Bool {
    if lhs.eventGuid != rhs.eventGuid {return false}
    if lhs._location != rhs._location {return false}
    if lhs._customer != rhs._customer {return false}
    if lhs._device != rhs._device {return false}
    if lhs._session != rhs._session {return false}
    if lhs._app != rhs._app {return false}
    if lhs._network != rhs._network {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Gojek_Clickstream_Internal_HealthMeta.NetworkType: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "NETWORK_TYPE_UNSPECIFIED"),
    1: .same(proto: "NETWORK_TYPE_NO_CONNECTION"),
    2: .same(proto: "NETWORK_TYPE_WIFI"),
    3: .same(proto: "NETWORK_TYPE_WWAN2G"),
    4: .same(proto: "NETWORK_TYPE_WWAN3G"),
    5: .same(proto: "NETWORK_TYPE_WWAN4G"),
  ]
}

extension Gojek_Clickstream_Internal_HealthMeta.App: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = Gojek_Clickstream_Internal_HealthMeta.protoMessageName + ".App"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "version"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularStringField(value: &self.version)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.version.isEmpty {
      try visitor.visitSingularStringField(value: self.version, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Gojek_Clickstream_Internal_HealthMeta.App, rhs: Gojek_Clickstream_Internal_HealthMeta.App) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Gojek_Clickstream_Internal_HealthMeta.Customer: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = Gojek_Clickstream_Internal_HealthMeta.protoMessageName + ".Customer"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "signed_up_country"),
    2: .standard(proto: "current_country"),
    3: .same(proto: "identity"),
    4: .same(proto: "email"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularStringField(value: &self.signedUpCountry)
      case 2: try decoder.decodeSingularStringField(value: &self.currentCountry)
      case 3: try decoder.decodeSingularInt32Field(value: &self.identity)
      case 4: try decoder.decodeSingularStringField(value: &self.email)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.signedUpCountry.isEmpty {
      try visitor.visitSingularStringField(value: self.signedUpCountry, fieldNumber: 1)
    }
    if !self.currentCountry.isEmpty {
      try visitor.visitSingularStringField(value: self.currentCountry, fieldNumber: 2)
    }
    if self.identity != 0 {
      try visitor.visitSingularInt32Field(value: self.identity, fieldNumber: 3)
    }
    if !self.email.isEmpty {
      try visitor.visitSingularStringField(value: self.email, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Gojek_Clickstream_Internal_HealthMeta.Customer, rhs: Gojek_Clickstream_Internal_HealthMeta.Customer) -> Bool {
    if lhs.signedUpCountry != rhs.signedUpCountry {return false}
    if lhs.currentCountry != rhs.currentCountry {return false}
    if lhs.identity != rhs.identity {return false}
    if lhs.email != rhs.email {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Gojek_Clickstream_Internal_HealthMeta.Device: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = Gojek_Clickstream_Internal_HealthMeta.protoMessageName + ".Device"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "operating_system"),
    2: .standard(proto: "operating_system_version"),
    3: .standard(proto: "device_make"),
    4: .standard(proto: "device_model"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularStringField(value: &self.operatingSystem)
      case 2: try decoder.decodeSingularStringField(value: &self.operatingSystemVersion)
      case 3: try decoder.decodeSingularStringField(value: &self.deviceMake)
      case 4: try decoder.decodeSingularStringField(value: &self.deviceModel)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.operatingSystem.isEmpty {
      try visitor.visitSingularStringField(value: self.operatingSystem, fieldNumber: 1)
    }
    if !self.operatingSystemVersion.isEmpty {
      try visitor.visitSingularStringField(value: self.operatingSystemVersion, fieldNumber: 2)
    }
    if !self.deviceMake.isEmpty {
      try visitor.visitSingularStringField(value: self.deviceMake, fieldNumber: 3)
    }
    if !self.deviceModel.isEmpty {
      try visitor.visitSingularStringField(value: self.deviceModel, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Gojek_Clickstream_Internal_HealthMeta.Device, rhs: Gojek_Clickstream_Internal_HealthMeta.Device) -> Bool {
    if lhs.operatingSystem != rhs.operatingSystem {return false}
    if lhs.operatingSystemVersion != rhs.operatingSystemVersion {return false}
    if lhs.deviceMake != rhs.deviceMake {return false}
    if lhs.deviceModel != rhs.deviceModel {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Gojek_Clickstream_Internal_HealthMeta.Location: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = Gojek_Clickstream_Internal_HealthMeta.protoMessageName + ".Location"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "latitude"),
    2: .same(proto: "longitude"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularDoubleField(value: &self.latitude)
      case 2: try decoder.decodeSingularDoubleField(value: &self.longitude)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.latitude != 0 {
      try visitor.visitSingularDoubleField(value: self.latitude, fieldNumber: 1)
    }
    if self.longitude != 0 {
      try visitor.visitSingularDoubleField(value: self.longitude, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Gojek_Clickstream_Internal_HealthMeta.Location, rhs: Gojek_Clickstream_Internal_HealthMeta.Location) -> Bool {
    if lhs.latitude != rhs.latitude {return false}
    if lhs.longitude != rhs.longitude {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Gojek_Clickstream_Internal_HealthMeta.Session: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = Gojek_Clickstream_Internal_HealthMeta.protoMessageName + ".Session"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "session_id"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularStringField(value: &self.sessionID)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.sessionID.isEmpty {
      try visitor.visitSingularStringField(value: self.sessionID, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Gojek_Clickstream_Internal_HealthMeta.Session, rhs: Gojek_Clickstream_Internal_HealthMeta.Session) -> Bool {
    if lhs.sessionID != rhs.sessionID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Gojek_Clickstream_Internal_HealthMeta.Network: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = Gojek_Clickstream_Internal_HealthMeta.protoMessageName + ".Network"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "type"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularEnumField(value: &self.type)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.type != .unspecified {
      try visitor.visitSingularEnumField(value: self.type, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Gojek_Clickstream_Internal_HealthMeta.Network, rhs: Gojek_Clickstream_Internal_HealthMeta.Network) -> Bool {
    if lhs.type != rhs.type {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
