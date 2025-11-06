//
//  CourierNetworkClient.swift
//  CourierFallbackPollingService
//
//  Created by Alfian Losari on 07/02/23.
//

import CourierCore
import CourierMQTT
import Foundation

final class CourierNetworkClient<T, C>: NetworkClient {

    private let messagePublisher: AnyPublisher<C, Never>
    private let courierMapper: ((C) -> T)?
    private let httpRequestHandler: (@escaping (Result<T, Error>) -> Void) -> Void

    var httpRequestOperation: HTTPRequestOperation<T>?
    var cancellable: AnyCancellable?

    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    init(httpResultHandler: @escaping (@escaping (Result<T, Error>) -> Void) -> Void,
         courierMessagePublisher: AnyPublisher<C, Never>,
         courierMessageMapper: ((C) -> T)?) throws {
        if C.self != T.self && courierMessageMapper == nil {
            throw NSError(domain: "CourierFallback.NetworkClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "provide Courier Message Mapper as \(type(of: C.self)) from Courier stream is different with \(type(of: T.self))"])
        }
        self.httpRequestHandler = httpResultHandler
        self.messagePublisher = courierMessagePublisher
        self.courierMapper = courierMessageMapper
    }

    func fetchFromHTTP(completion: @escaping (Result<T, Error>) -> ()) {
        cancelPendingHTTPRequest()
        
        let operation: HTTPRequestOperation<T> = .init(httpRequestHandler: self.httpRequestHandler, completion: { [weak self] result in
            guard self != nil else { return }
            completion(result)
        })
        self.httpRequestOperation = operation
        operationQueue.addOperation(operation)
    }

    func listenFromCourier(listener: @escaping (Result<T, Error>) -> ()) {
        cancelCourierListener()
        self.cancellable =  self.messagePublisher
            .sink { [weak self] message in
                guard let mappedMessage = self?.mapCourierMessage(message: message) else { return }
                listener(mappedMessage)
            }
    }

    func cancelCourierListener() {
        cancellable?.cancel()
        cancellable = nil
    }

    func cancelPendingHTTPRequest() {
        httpRequestOperation?.cancel()
        httpRequestOperation = nil
    }

    func mapCourierMessage(message: C) -> Result<T, Error> {
        if let message = message as? T {
            return .success(message)
        } else if let mapper = self.courierMapper {
            return .success(mapper(message))
        } else {
            return .failure(NSError(domain: "CourierFallback.NetworkClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to map Courier response \(type(of: C.self)) to expected \(type(of: T.self)). Please provide a mapper closure in the initializer"]))
        }
    }

    deinit {
        cancelPendingHTTPRequest()
        cancelCourierListener()
    }
}
