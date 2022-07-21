//
//  SocketHandlerMock.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 04/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

enum SocketConnectionState {
    case successWithData
    case successWithEmptyData
    case successWithNonSerializedData
    case failure
}

final class SocketHandlerMockSuccess: SocketHandler {
    
    private var connectionCallback: ConnectionStatus?
    
    static var state: SocketConnectionState = .successWithData
    
    init(performOnQueue: SerialQueue) {
        
    }
    
    func setup(request: URLRequest, keepTrying: Bool, connectionCallback: ConnectionStatus?) {
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
    
    var isConnected: Atomic<Bool> {
        return Atomic(true)
    }
}
