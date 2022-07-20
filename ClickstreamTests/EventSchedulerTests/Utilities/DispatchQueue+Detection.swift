//
//  SerialQueue+Detection.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 20/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//  Refered from: https://stackoverflow.com/a/60314121

@testable import Clickstream
import Foundation

extension SerialQueue {

    private struct QueueReference { weak var queue: SerialQueue? }

    private static let key: DispatchSpecificKey<QueueReference> = {
        let key = DispatchSpecificKey<QueueReference>()
        setupSystemQueuesDetection(key: key)
        return key
    }()

    private static func _registerDetection(of queues: [SerialQueue], key: DispatchSpecificKey<QueueReference>) {
        queues.forEach { $0.setSpecific(key: key, value: QueueReference(queue: $0)) }
    }

    private static func setupSystemQueuesDetection(key: DispatchSpecificKey<QueueReference>) {
        let queues: [SerialQueue] = [
                                        .main,
                                        .global(qos: .background),
                                        .global(qos: .default),
                                        .global(qos: .unspecified),
                                        .global(qos: .userInitiated),
                                        .global(qos: .userInteractive),
                                        .global(qos: .utility)
                                    ]
        _registerDetection(of: queues, key: key)
    }
}

// MARK: public functionality

extension SerialQueue {
    static func registerDetection(of queue: SerialQueue) {
        _registerDetection(of: [queue], key: key)
    }

    static var currentQueueLabel: String? { current?.label }
    static var current: SerialQueue? { getSpecific(key: key)?.queue }
}
