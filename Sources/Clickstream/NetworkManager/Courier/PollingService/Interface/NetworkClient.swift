//
//  NetworkClient.swift
//  FallbackPollingService
//
//  Created by Alfian Losari on 07/02/23.
//

import Foundation

protocol NetworkClient {

    associatedtype T

    func fetchFromHTTP(completion: @escaping (Result<T, Error>) -> ())
    func listenFromCourier(listener: @escaping (Result<T, Error>) -> ())

    func cancelPendingHTTPRequest()
    func cancelCourierListener()
}
