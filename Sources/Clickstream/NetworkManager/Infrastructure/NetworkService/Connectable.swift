//
//  Connectable.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 27/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

typealias ConnectionStatus = (Result<ConnectableState, ConnectableError>) -> ()

enum ConnectableState {
    case connected
    case disconnected
    case connecting
    case cancelled
}

enum ConnectableError: Error {
    case networkError(Error)
    case failed
    case malformedPath
    case noResponse
    case parsingData
}
