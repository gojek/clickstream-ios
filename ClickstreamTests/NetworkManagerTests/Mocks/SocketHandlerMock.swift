//
//  SocketHandlerMock.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 04/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import ClickstreamLib
import Foundation

enum SocketConnectionState {
    case successWithData
    case successWithEmptyData
    case successWithNonSerializedData
    case failure
}

final class SocketHandlerMockSuccess: SocketHandler {
    
    static var state: SocketConnectionState = .successWithData
    
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
        switch SocketHandlerMockSuccess.state {
        case .successWithData:
            completion(.success(data))
        case .successWithEmptyData:
            completion(.success(nil))
        case .successWithNonSerializedData:
            completion(.success(data.dropFirst()))
        case .failure:
            completion(.failure(.networkError(NSError(domain:"", code:404, userInfo:nil))))
        }
    }
    
    func disconnect() {
        connectionCallback?(.success(.disconnected))
    }
    
    var isConnected: Bool {
        true
    }
}
