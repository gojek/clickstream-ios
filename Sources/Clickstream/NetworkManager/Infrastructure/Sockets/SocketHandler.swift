//
//  SocketHandler.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import Reachability
import Starscream

protocol SocketHandler: Connectable, HeartBeatable { }

final class DefaultSocketHandler: SocketHandler {

    private static var retries = 0
    private var open: Bool
    private var connected: Bool
    private let request: URLRequest
    private let connectionCallback: ConnectionStatus?
    private var webSocket: WebSocket?
    private let mutex = NSLock()
    private var pingTimer: DispatchSourceTimer?
    private var writeCallback: ((Result<Data?, ConnectableError>) -> Void)?
    private let performQueue: SerialQueue
    private var isRetryInProgress: Bool = false
    /// Records the time stamp for the last connection request made
    private var lastConnectRequestTimestamp: Date?
    
    var isConnected: Bool {
        get {
            mutex.lock()
            let isConnected = connected
            mutex.unlock()
            return isConnected
        }
    }
    
    init(request: URLRequest,
         keepTrying: Bool,
         performOnQueue: SerialQueue,
         connectionCallback: ConnectionStatus?) {
        self.open = false
        self.connected = false
        self.performQueue = performOnQueue
        self.request = request
        self.connectionCallback = connectionCallback
        
        webSocket = WebSocket(request: request)
        webSocket?.callbackQueue = performQueue
        // Add socket event listener
        addSocketEventListener()
        // Negotiate connection
        if keepTrying {
            negotiateConnection(initiate: true,
                                maxInterval: Clickstream.constraints.maxConnectionRetryInterval,
                                maxRetries: Clickstream.constraints.maxConnectionRetries)
        } else {
            negotiateConnection(initiate: true)
        }
    }
    
    /// Negotiates a connection, by calling the
    /// - Parameters:
    ///   - initiate: A control flag to control whether the negotiation should de initiated or not.
    ///   - maxInterval: A given max interval for the retries.
    ///   - maxRetries: A given number of max retry attempts
    private func negotiateConnection(initiate: Bool, maxInterval: TimeInterval = 0.0, maxRetries: Int = 0) {
        
        if connected || DefaultSocketHandler.retries > maxRetries {
            isRetryInProgress = false
            DefaultSocketHandler.retries = 0 // Reset to zero for further negotiation calls.
            return
        } else if initiate || DefaultSocketHandler.retries > 0 {
            if !open {
                lastConnectRequestTimestamp = Date()
                print("socket-connecting", .verbose)
                Clickstream.connectionState = .connecting
                connectionCallback?(.success(.connecting))
                webSocket?.connect()
            }
        }
        if DefaultSocketHandler.retries < maxRetries {
            performQueue.asyncAfter(deadline: .now() +
                min(pow(Constants.Defaults.coefficientOfConnectionRetries*connectionRetryCoefficient,
                        Double(DefaultSocketHandler.retries+1)), maxInterval)) {
                [weak self] in guard let checkedSelf = self else { return }
                checkedSelf.negotiateConnection(initiate: false, maxInterval: maxInterval, maxRetries: maxRetries)
            }
            DefaultSocketHandler.retries += 1
        }
    }
    
    deinit {
        disconnect()
        stopPing()
        webSocket?.delegate = nil
    }
}

extension DefaultSocketHandler {
        
    func write(_ data: Data, completion: @escaping ((Result<Data?, ConnectableError>) -> Void)) {
        webSocket?.write(data: data)
        self.writeCallback = completion
    }
    
    func disconnect() {
        stopPing()
        Clickstream.connectionState = .closed
        webSocket?.disconnect(closeCode: CloseCode.normal.rawValue)
    }
}

extension DefaultSocketHandler {
    func sendPing(_ data: Data) {
        guard pingTimer == nil else {
            return
        }
        pingTimer = DispatchSource.makeTimerSource(flags: .strict)
        pingTimer?.schedule(deadline: .now() + Clickstream.constraints.maxPingInterval,
                            repeating: Clickstream.constraints.maxPingInterval)
        pingTimer?.setEventHandler(handler: { [weak self] in
            self?.keepAlive(data)
        })
        pingTimer?.resume()
    }
    
    func stopPing() {
        pingTimer?.cancel()
        pingTimer = nil
    }
    
    private func keepAlive(_ data: Data) {
        if open {
            webSocket?.write(ping: data)
        }
    }
}

extension DefaultSocketHandler {
    // swiftlint:disable:next cyclomatic_complexity
    private func addSocketEventListener() {
        webSocket?.onEvent = { [weak self] event in guard let checkedSelf = self else { return }
            switch event {
            case .connected:
                print("connected",.critical)
                Clickstream.connectionState = .connected
                checkedSelf.connected = true
                checkedSelf.isRetryInProgress = false
                checkedSelf.sendPing(Data())
                checkedSelf.connectionCallback?(.success(.connected))
                #if TRACKER_ENABLED
                if Tracker.debugMode {
                    let timeInterval = Date().timeIntervalSince(checkedSelf.lastConnectRequestTimestamp ?? Date())
                    let event = HealthAnalysisEvent(eventName: .ClickstreamConnectionSuccess,
                                                    timeToConnection: ("\(timeInterval)"))
                    Tracker.sharedInstance?.record(event: event)
                }
                #endif
            case .disconnected(let error, let code):
                // DuplicateID Error
                print("disconnected with error: \(error) errorCode: \(code)", .critical)
                Clickstream.connectionState = .closed
                checkedSelf.open = false
                checkedSelf.stopPing()
                #if TRACKER_ENABLED
                if Tracker.debugMode {
                    checkedSelf.trackHealthEvent(eventName: .ClickstreamConnectionDropped, code: code)
                }
                #endif
            case .text(let responseString):
                checkedSelf.writeCallback?(.success(responseString.data(using: .utf8)))
            case .error(let error):
                if let error = error {
                    print("error \(error)", .verbose)
                }
                if error.debugDescription.contains(Constants.Strings.connectionError) {
                    checkedSelf.open = false
                    checkedSelf.stopPing()
                    checkedSelf.retryConnection()
                }
                checkedSelf.writeCallback?(.failure(.failed))
                #if TRACKER_ENABLED
                if Tracker.debugMode {
                    let timeInterval = Date().timeIntervalSince(checkedSelf.lastConnectRequestTimestamp ?? Date())
                    self?.trackHealthEvent(eventName: .ClickstreamConnectionFailure, error: error, timeToConnection: ("\(timeInterval)"))
                }
                #endif
                
            case .binary(let response):
                checkedSelf.writeCallback?(.success(response))
            case .pong:
                print("pong", .verbose)
            case .cancelled:
                print("cancelled", .verbose)
                Clickstream.connectionState = .failed
                checkedSelf.open = false
                checkedSelf.connected = false
                checkedSelf.stopPing()
                checkedSelf.connectionCallback?(.success(.cancelled))
            case .ping:
                print("ping", .verbose)
            case .viabilityChanged(let status):
                checkedSelf.open = status
            case .reconnectSuggested(let status):
                print("reconnectSuggested", .verbose)
                if status {
                    checkedSelf.open = false
                    checkedSelf.stopPing()
                    checkedSelf.retryConnection()
                }
            }
        }
    }
    
    private func retryConnection() {
        print("retryingConnection")
        if isRetryInProgress {
            return
        }
        if connected {
            connected = false
            connectionCallback?(.success(.disconnected))
        }
    }
}

extension SocketHandler {
    var connectionRetryCoefficient: TimeInterval {
        get {
            let networkType = Reachability.getNetworkType()
            switch networkType {
            case .wifi:
                return 1
            case .wwan4g:
                return 1.3
            case .wwan3g:
                return 1.6
            case .wwan2g:
                return 2.2
            default:
                return 1
            }
        }
    }
}

// MARK: - Track Clickstream health.
extension DefaultSocketHandler {
    #if TRACKER_ENABLED
    func trackHealthEvent(eventName: HealthEvents,
                          error: Error? = nil, code: UInt16? = nil, timeToConnection: String? = nil) {
        guard Tracker.debugMode else { return }
        if let error = error {
            if case HTTPUpgradeError.notAnUpgrade(let code) = error {
                if code == 401 {
                    let event = HealthAnalysisEvent(eventName: eventName,
                                                    reason: FailureReason.AuthenticationError.rawValue, timeToConnection: timeToConnection)
                    Tracker.sharedInstance?.record(event: event)
                } else if code == 1008 {
                    let event = HealthAnalysisEvent(eventName: eventName,
                                                    reason: FailureReason.DuplicateID.rawValue, timeToConnection: timeToConnection)
                    Tracker.sharedInstance?.record(event: event)
                } else {
                    let event = HealthAnalysisEvent(eventName: eventName,
                                                    reason: error.localizedDescription, timeToConnection: timeToConnection)
                    Tracker.sharedInstance?.record(event: event)
                }
            } else {
                let event = HealthAnalysisEvent(eventName: eventName,
                                                reason: error.localizedDescription, timeToConnection: timeToConnection)
                Tracker.sharedInstance?.record(event: event)
            }
        } else if code == 1008 {
            let event = HealthAnalysisEvent(eventName: eventName,
                                            reason: FailureReason.DuplicateID.rawValue, timeToConnection: timeToConnection)
            Tracker.sharedInstance?.record(event: event)
        }
    }
    #endif
}
