import Foundation
import SwiftProtobuf
import GRDB

protocol EventPersistable: Codable, Comparable, Hashable {
    var guid: String { get }
    var timestamp: Date { get }
    var type: PriorityType { get }
    var isMirrored: Bool { get }
    var eventProtoData: Data { get }
}

extension EventPersistable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}
