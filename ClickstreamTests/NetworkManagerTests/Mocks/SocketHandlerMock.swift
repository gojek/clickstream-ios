//
//  SocketHandlerMock.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 04/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import Foundation

final class SocketHandlerMockSuccess: SocketHandler {
    
    private let connectionCallback: ConnectionStatus?
    
    func sendPing(_ data: Data) { }
    
    func stopPing() { }
    
    init(request: URLRequest, keepTrying: Bool, performOnQueue: SerialQueue, connectionCallback: ConnectionStatus?) {
        self.connectionCallback = connectionCallback
        SerialQueue.main.asyncAfter(deadline: .now() + 0.5) {
           connectionCallback?(.success(.connected))//change this. -AV
        }
    }
    
    func write(_ data: Data, completion: @escaping ((Result<Data?, ConnectableError>) -> Void)) {
        completion(.success(data))
    }
    
    func disconnect() {
        connectionCallback?(.success(.disconnected))
    }
    
    var isConnected: Bool {
        true
    }
}
