//
//  RetryMechanism.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 29/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol RetryableInputs {
    
    /// Call this function to flush eventBatches.
    /// - Parameter eventRequest: eventRequest Object to flush
    func trackBatch(with eventRequest: EventRequest)
    
    func openConnectionForcefully()
    
    /**
     Call this function to stop tracking.
    - Internally:
        * Terminates the connection.
        * Stops reachability notifier.
    */
    func stopTracking()
}

protocol RetryableOutputs {
    var isAvailble: Bool { get }
}

protocol Retryable: RetryableInputs, RetryableOutputs {}

/// This class is holds the retry logic for the SDK. NetworkBuilder routes the requests through RetryMechanism.
final class DefaultRetryMechanism: Retryable {
    
    private var reachability: NetworkReachability
    private let networkService: NetworkService
    private let performQueue: SerialQueue
    private var deviceStatus: DefaultDeviceStatus
    private let appStateNotifier: AppStateNotifierService
    private var terminationCountDown: DispatchSourceTimer?
    private var networkServiceState: ConnectableState = .disconnected
    private var persistence: DefaultDatabaseDAO<EventRequest>
    private var retryTimer: DispatchSourceTimer?
    private var keepAliveService: KeepAliveService
    
    var isAvailble: Bool {
        
        let isReachable = reachability.isAvailable
        let isConnected = networkService.isConnected
        let isOnLowPower = deviceStatus.isDeviceLowOnPower
        
        return isReachable && isConnected && !isOnLowPower
    }
    
    init(networkService: NetworkService,
         reachability: NetworkReachability,
         deviceStatus: DefaultDeviceStatus,
         appStateNotifier: AppStateNotifierService,
         performOnQueue: SerialQueue,
         persistence: DefaultDatabaseDAO<EventRequest>,
         keepAliveService: KeepAliveService) {
        self.networkService = networkService
        self.reachability = reachability
        self.performQueue = performOnQueue
        self.deviceStatus = deviceStatus
        self.appStateNotifier = appStateNotifier
        self.persistence = persistence
        self.keepAliveService = keepAliveService
        
        self.establishConnection()
        self.observeDeviceStatus()
        self.observeAppStateChanges()
        self.observeNetworkConnectivity()
        self.keepConnectionAlive()
    }
    
    /// Adding a subscription to the app state changes.
    private func observeAppStateChanges() {
        appStateNotifier.start { [weak self] (stateNotification) in guard let checkedSelf = self else { return }
            switch stateNotification {
            case .willResignActive:
                checkedSelf.keepAliveService.stop()
                checkedSelf.prepareForTerminatingConnection()
            case .didBecomeActive:
                checkedSelf.keepConnectionAlive()
                checkedSelf.cancelTerminationCountDown()
                checkedSelf.establishConnection()
            default:
                break
            }
        }
    }
        
    private func observeNetworkConnectivity() {
        do {
            try reachability.startNotifier()
        } catch {
            print("Error: unable to start notifier \(error)", .verbose)
        }
    }
    
    private func observeDeviceStatus() {
        deviceStatus.startTracking()
        deviceStatus.onBatteryStatusChanged = { [weak self] isLowOnPower in
            guard let checkedSelf = self else { return }
            /* If network is not connected and the device was on low power,
               now device is on charging state so establish the connection */
            if !checkedSelf.networkService.isConnected && isLowOnPower {
                checkedSelf.establishConnection()
                // If network is connected but device is on low power, terminate the connection
            } else if checkedSelf.networkService.isConnected && !isLowOnPower {
                checkedSelf.terminateConnection()
            }
        }
    }
    
    private func keepConnectionAlive() {
        keepAliveService.start { [weak self] in
            guard let checkedSelf = self else { return }
            let isReachable = checkedSelf.reachability.isAvailable
            let isConnected = checkedSelf.networkService.isConnected
            let isOnLowPower = checkedSelf.deviceStatus.isDeviceLowOnPower
            
            if isReachable && !isConnected && !isOnLowPower {
                checkedSelf.networkService.flushConnectable()
                checkedSelf.establishConnection()
            }
        }
    }
    
    private func cancelTerminationCountDown() {
        terminationCountDown?.cancel()
        terminationCountDown = nil
    }
    
    deinit {
        stopTracking()
    }
}

extension DefaultRetryMechanism {
    
    func trackBatch(with eventRequest: EventRequest) {
        // add the batch to the cache before sending the batch to the network.
        // QoS-0 don't support the caching
        if let eventType = eventRequest.eventType, eventType != .instant {
            addToCache(with: eventRequest)
        }
        performQueue.async(flags: .barrier) { [weak self] in
            guard let checkedSelf = self, let data = eventRequest.data else {
                return
            }
            checkedSelf.networkService.write(data) { (result: Result<Odpf_Raccoon_EventResponse, ConnectableError>) in
                switch result {
                case .success(let response):
                    if response.status == .success && response.code == .ok {
                        if let guid = response.data["req_guid"] {
                            // remove the delivered batch from the cache.
                            checkedSelf.removeFromCache(with: guid)
                        }
                    } else {
                        if response.code == .maxConnectionLimitReached {
                            checkedSelf.terminateConnection()
                            checkedSelf.establishConnection()
                        }
                        
                        if response.code == .maxUserLimitReached {
                            print("Error: max user limit reached", .verbose)
                        }
                        
                        if response.code == .badRequest {
                            print("Error: Parsing Exception for eventRequest guid \(eventRequest.guid)", .verbose)
                        }
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription) for eventRequest guid \(eventRequest.guid)", .verbose)
                }
            }
        }
    }
    
    func openConnectionForcefully() {
        establishConnection(keepTrying: true)
    }
    
    func stopTracking() {
        keepAliveService.stop()
        appStateNotifier.stop()
        deviceStatus.stopTracking()
        reachability.stopNotifier()
        terminateConnection()
    }
}

extension DefaultRetryMechanism {
    
    private func terminateConnection() {
        networkService.terminateConnection()
        stopObservingFailedBatches()
    }
    
    private func prepareForTerminatingConnection() {
        
        let semaphore = DispatchSemaphore(value: 1)
        defer {
            semaphore.signal()
        }
        semaphore.wait()
        
        guard terminationCountDown == nil else {
            return
        }
        terminationCountDown = DispatchSource.makeTimerSource(flags: .strict, queue: performQueue)
        // This gives the breathing space for flushing the events.
        terminationCountDown?.schedule(deadline: .now() + Clickstream.constraints.connectionTerminationTimerWaitTime)
        terminationCountDown?.setEventHandler(handler: { [weak self] in guard let checkedSelf = self else { return }
            checkedSelf.terminateConnection()
        })
        terminationCountDown?.resume()
    }
    
    private func establishConnection(keepTrying: Bool = false) {
//        return
        let semaphore = DispatchSemaphore(value: 1)
        defer {
            semaphore.signal()
        }
        semaphore.wait()
        
        if self.networkService.isConnected || !reachability.isAvailable {
            return
        }
        
        performQueue.async { [weak self] in guard let checkedSelf = self else { return }
            checkedSelf.networkService.initiateConnection(connectionStatusListener: { [weak self] result in

                NotificationCenter.default.post(name: Constants.SocketConnectionNotification,
                                                object: [Constants.Strings.didConnect: self?.networkService.isConnected])

                guard let checkedSelf = self else {
                    return
                }
                switch result {
                case .success(let state):
                    switch state {
                    case .connected:
                        checkedSelf.startObservingFailedBatches()
                    case .cancelled, .disconnected:
                        checkedSelf.stopObservingFailedBatches()
                        checkedSelf.networkService.flushConnectable()
                    default:
                        break
                    }
                    checkedSelf.networkServiceState = state
                case .failure:
                    checkedSelf.stopObservingFailedBatches()
                }
            }, keepTrying: keepTrying)
        }
    }

}

extension DefaultRetryMechanism {
    
    private func addToCache(with eventRequest: EventRequest) {
        if var fetchedEventRequest = persistence.fetchOne(eventRequest.guid) {
            if fetchedEventRequest.retriesMade >= Clickstream.constraints.maxRetriesPerBatch {
                persistence.deleteOne(eventRequest.guid)
            } else {
                fetchedEventRequest.bumpRetriesMade() // This will bump the retriesMade.
                fetchedEventRequest.refreshCachingTimeStamp() // This will update the timestamp with the latest retry time.
                persistence.update(fetchedEventRequest)
            }
        } else {
            persistence.insert(eventRequest)
        }
    }
    
    private func removeFromCache(with id: String) {
        persistence.deleteOne(id)
    }
    
    private func startObservingFailedBatches() {
        guard retryTimer == nil else { return }
        retryTimer = DispatchSource.makeTimerSource(flags: .strict, queue: performQueue)
        retryTimer?.schedule(deadline: .now() + Clickstream.constraints.maxRequestAckTimeout,
                             repeating: Clickstream.constraints.maxRequestAckTimeout)
        retryTimer?.setEventHandler(handler: { [weak self] in
            guard let checkedSelf = self else { return }
            checkedSelf.retryFailedBatches()
        })
        retryTimer?.resume()
    }
    
    private func stopObservingFailedBatches() {
        retryTimer?.cancel()
        retryTimer = nil
    }
    
    
    private func retryFailedBatches() {
        if let failedRequests = persistence.fetchAll(), !failedRequests.isEmpty {
            let date = Date()
            let timedOutRequests = failedRequests.filter {
                (date.timeIntervalSince1970 - $0.timeStamp.timeIntervalSince1970) >= Clickstream.constraints.maxRequestAckTimeout
            }
            
            // If no timedOut requests are found then do nothing and return.
            if timedOutRequests.isEmpty {
                return
            }
            
            let retryCoefficient = (Clickstream.constraints.maxRequestAckTimeout/Double(timedOutRequests.count))/2
            for (index,batch) in timedOutRequests.enumerated() {
                var _batch = batch
                performQueue.asyncAfter(deadline: .now() + (retryCoefficient * Double(index))) { [weak self] in
                    guard let checkedSelf = self else {
                        return
                    }
                    
                    do {
                        // Refresh the timeStamp before sending the batch!
                        try _batch.refreshBatchSentTimeStamp()
                    } catch {
                        print("Failed to update batch time on retry. Description: \(error)",.critical)
                    }
                    checkedSelf.trackBatch(with: _batch)
                }
            }
        }
    }
}
