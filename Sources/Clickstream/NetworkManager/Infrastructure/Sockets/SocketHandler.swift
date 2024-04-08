//
//  SocketHandler.swift
//  ClickStream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import Reachability
import Starscream

protocol SocketHandler: Connectable { }

final class DefaultSocketHandler: SocketHandler {
      
    
    /// Used as a websocket callback queue.
    private let performQueue: SerialQueue
    
    /// States whether the socket request is open.
    private var isConnectionRequestOpen: Bool = false
    
    /// Refers to the `URLRequest` for setting up a socket connection
    private var request: URLRequest?
    
    /// Callback for the socket status
    private var connectionCallback: ConnectionStatus?
    
    /// Holds the number of retries made for negotiating a connection.
    private static var retries = 0
    
    /// Websocket.
    private var webSocket: WebSocket?
    
    /// Callback for a socket `write` action
    private var writeCallback: ((Result<Data?, ConnectableError>) -> Void)?
    
    /// Tracking time taken by the socket to establish a connection
    #if TRACKER_ENABLED
    private var socketConnectionTimeTrace: Trace = Trace(name: TrackerConstant.Traces.ClickstreamSocketConnectionTime.rawValue)
    #endif
    
    /// Provides the socket state
    var isConnected: Atomic<Bool> = Atomic(false)
    
    /// Records the time stamp for the last connection request made
    private var lastConnectRequestTimestamp: Date?

    /// Custom Socket Handler initialiser
    /// - Parameter performOnQueue: Queue on which a socket performs actions
    init(performOnQueue: SerialQueue) {
        self.performQueue = performOnQueue
        DefaultSocketHandler.retries = 0
    }
    
    /// Attempt at making a connection
    /// - Parameters:
    ///   - request: URLRequest for setting up socket connection
    ///   - keepTrying: Suggests if the connection attempts should tried multiple times
    ///   - connectionCallback: Connection callback closure provides with the state of the socket as `ConnectionStatus`
    func setup(request: URLRequest,
               keepTrying: Bool,
               connectionCallback: ConnectionStatus?) {
        
        guard self.isConnectionRequestOpen == false || !request.isEqual(to: self.request) else { return }
        self.isConnected.mutate { isConnected in
            isConnected = false
        }
        self.connectionCallback = connectionCallback
        self.request = request
        webSocket = WebSocket(request: request)
        webSocket?.callbackQueue = performQueue
        webSocket?.respondToPingWithPong = true
        // Add socket event listener
        addSocketEventListener()
        // Negotiate connection
        if keepTrying {
            negotiateConnection(initiate: true,
                                maxInterval: Clickstream.configurations.maxConnectionRetryInterval,
                                maxRetries: Clickstream.configurations.maxConnectionRetries)
        } else {
            negotiateConnection(initiate: true)
        }
    }

    /// Negotiates a connection, by calling the
    /// - Parameters:
    ///   - initiate: A control flag to control whether the negotiation should de initiated or not.
    ///   - maxInterval: A given max interval for the retries.
    ///   - maxRetries: A given number of max retry attempts
    private func negotiateConnection(initiate: Bool,
                                     maxInterval: TimeInterval = 0.0,
                                     maxRetries: Int = 0) {
        
        if isConnected.value || DefaultSocketHandler.retries > maxRetries {
            // Exit Condition.
            // Reset to zero for further negotiation calls.
            DefaultSocketHandler.retries = 0
            return
        } else if initiate || DefaultSocketHandler.retries > 0 {
            if !isConnectionRequestOpen ||
                Date().timeIntervalSince(lastConnectRequestTimestamp ?? Date()) > self.request?.timeoutInterval ?? 60 {
                Clickstream.connectionState = .connecting
                print("socket-connecting")
                isConnectionRequestOpen = true
                connectionCallback?(.success(.connecting))
                #if TRACKER_ENABLED
                socketConnectionTimeTrace.attributes = [Constants.Strings.networkType: Reachability.getNetworkType().trackingId]
                socketConnectionTimeTrace.start()
                #endif
                webSocket?.connect()
                lastConnectRequestTimestamp = Date() // recording time
            }
        }
        if DefaultSocketHandler.retries < maxRetries {
            performQueue.asyncAfter(deadline: .now() +
                                    min(pow(Constants.Defaults.coefficientOfConnectionRetries*connectionRetryCoefficient,
                                            Double(DefaultSocketHandler.retries)), maxInterval)) {
                [weak self] in guard let checkedSelf = self else { return }
                checkedSelf.negotiateConnection(initiate: false,
                                                maxInterval: maxInterval,
                                                maxRetries: maxRetries)
            }
            DefaultSocketHandler.retries += 1
        }
    }
    
    deinit {
        #if TRACKER_ENABLED
        socketConnectionTimeTrace.attributes = [Constants.Strings.networkType: Reachability.getNetworkType().trackingId,
                                                Constants.Strings.status: Constants.Strings.failure]
        socketConnectionTimeTrace.stop()
        #endif
        print("socket-deinit")
    }
}

extension DefaultSocketHandler {
    
    /// Writing data on the socket connection.
    /// - Parameters:
    ///   - data: data to be returned
    ///   - completion: completion callback
    func write(_ data: Data,
               completion: @escaping ((Result<Data?, ConnectableError>) -> Void)) {
        webSocket?.write(data: data)
        self.writeCallback = completion
    }
    
    /// Call this to disconnect from the socket.
    func disconnect() {
        print("socket-disconnect")
        webSocket?.disconnect(closeCode: CloseCode.normal.rawValue)
        Clickstream.connectionState = .closed
        reset()
    }
    
    /// Resets the state variables and socket event listeners.
    private func reset() {
        print("socket-reset-connection")
        isConnectionRequestOpen = false
        webSocket?.onEvent = nil
        self.isConnected.mutate { isConnected in
            isConnected = false
        }
    }
}

extension DefaultSocketHandler {
    // swiftlint:disable:next cyclomatic_complexity
    private func addSocketEventListener() {
        webSocket?.onEvent = { [weak self] event in guard let checkedSelf = self else { return }
            print("socket-onEvent: \(event)")
            switch event {
            case .connected:
                Clickstream.connectionState = .connected
                checkedSelf.isConnected.mutate { isConnected in
                    isConnected = true
                }
                checkedSelf.isConnectionRequestOpen = false
                checkedSelf.connectionCallback?(.success(.connected))
                #if TRACKER_ENABLED
                checkedSelf.socketConnectionTimeTrace.attributes = [Constants.Strings.networkType: Reachability.getNetworkType().trackingId,
                                                                    Constants.Strings.status: Constants.Strings.success]
                checkedSelf.socketConnectionTimeTrace.stop()
                #endif
            case .disconnected(let error, let code):
                print("disconnected with error: \(error) errorCode: \(code)", .critical)
                Clickstream.connectionState = .closed
                checkedSelf.isConnectionRequestOpen = false
                #if TRACKER_ENABLED
                checkedSelf.socketConnectionTimeTrace.attributes = [Constants.Strings.networkType: Reachability.getNetworkType().trackingId,
                                                                    Constants.Strings.status: Constants.Strings.failure]
                checkedSelf.socketConnectionTimeTrace.stop()
                let errorObject = NSError(domain: "", code: Int(code), userInfo: [NSLocalizedDescriptionKey: error])
                checkedSelf.trackHealthEvent(eventName: .ClickstreamConnectionDropped, error: errorObject, code: code)
                #endif
            case .text(let responseString):
                checkedSelf.writeCallback?(.success(responseString.data(using: .utf8)))
            case .error(let error):
                checkedSelf.isConnectionRequestOpen = false
            #if TRACKER_ENABLED
                checkedSelf.socketConnectionTimeTrace.attributes = [Constants.Strings.networkType: Reachability.getNetworkType().trackingId,
                                                                    Constants.Strings.status: Constants.Strings.failure]
                checkedSelf.socketConnectionTimeTrace.stop()
                    let timeInterval = Date().timeIntervalSince(checkedSelf.lastConnectRequestTimestamp ?? Date())
                    self?.trackHealthEvent(eventName: .ClickstreamConnectionFailure, error: error, timeToConnection: ("\(timeInterval)"))
            #endif
                checkedSelf.writeCallback?(.failure(.failed))
            case .binary(let response):
                checkedSelf.writeCallback?(.success(response))
            case .cancelled:
                Clickstream.connectionState = .failed
                checkedSelf.retryConnection()
                checkedSelf.connectionCallback?(.success(.cancelled))
            case .viabilityChanged(let status):
                checkedSelf.isConnectionRequestOpen = status
            case .peerClosed:
                checkedSelf.isConnectionRequestOpen = false
            default:
                break
            }
        }
    }
    
    /// Retries socket connection when `.cancelled` state of the socket is received.
    private func retryConnection() {
        isConnectionRequestOpen = false
        isConnected.mutate { isConnected in
            isConnected = false
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

extension DefaultSocketHandler {
#if TRACKER_ENABLED
    func trackHealthEvent(eventName: HealthEvents,
                          error: Error? = nil,
                          code: UInt16? = nil,
                          timeToConnection: String? = nil) {
        
        guard Tracker.debugMode else { return }
        if let error = error, case HTTPUpgradeError.notAnUpgrade(let code) = error {
            
            if code.0 == 401 {
                let event = HealthAnalysisEvent(eventName: eventName,
                                                reason: FailureReason.AuthenticationError.rawValue)
                Tracker.sharedInstance?.record(event: event)
            } else if code.0 == 1008 {
                let event = HealthAnalysisEvent(eventName: eventName,
                                                reason: FailureReason.DuplicateID.rawValue)
                Tracker.sharedInstance?.record(event: event)
            } else {
                let event = HealthAnalysisEvent(eventName: eventName,
                                                reason: error.localizedDescription)
                Tracker.sharedInstance?.record(event: event)
            }
        } else if code == 1008 {
            let event = HealthAnalysisEvent(eventName: eventName,
                                            reason: FailureReason.DuplicateID.rawValue)
            Tracker.sharedInstance?.record(event: event)
        } else {
            let event = HealthAnalysisEvent(eventName: eventName,
                                            reason: error?.localizedDescription)
            Tracker.sharedInstance?.record(event: event)
        }
    }
#endif
}
