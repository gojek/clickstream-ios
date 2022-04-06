//
//  ProtoConvertible.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 30/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol ProtoConvertible {
    associatedtype ProtoMessage: Message
    var proto: ProtoMessage { get }
}
