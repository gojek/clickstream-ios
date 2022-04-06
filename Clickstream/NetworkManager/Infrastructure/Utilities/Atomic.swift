//
//  Atomic.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 09/03/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import Foundation

final class Atomic<T> {
    private let dispatchQueue = DispatchQueue(label: Constants.QueueIdentifiers.atomicAccess.rawValue, attributes: .concurrent)
    private var _value: T
    public init(_ value: T) {
        self._value = value
    }

    public var value: T { dispatchQueue.sync { _value } }

    public func mutate(execute task: (inout T) -> Void) {
        dispatchQueue.sync(flags: .barrier) { task(&_value) }
    }
}
