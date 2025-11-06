//
//  AsyncOperation.swift
//  CourierFallbackPollingService
//
//  Created by Alfian Losari on 08/02/23.
//

import Foundation

open class HTTPRequestOperation<T>: BaseAsyncOperation {

    private let httpRequestHandler: (@escaping (Result<T, Error>) -> Void) -> Void
    private let completion: (Result<T, Error>) -> Void

    init(
        httpRequestHandler: @escaping (@escaping (Result<T, Error>) -> Void) -> Void,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        self.httpRequestHandler = httpRequestHandler
        self.completion = completion
    }

    public override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            self.httpRequestHandler { [weak self] result in
                guard let self = self, !self.isCancelled else {
                    self?.asyncFinish()
                    return
                }
                self.completion(result)
                self.asyncFinish()
            }
        }
    }
}
