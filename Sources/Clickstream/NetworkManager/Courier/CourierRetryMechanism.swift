//
//  CourierRetryMechanism.swift
//  Clickstream
//
//  Created by Luqman Fauzi on 06/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import Foundation

final class CourierRetryMechanism: Retryable {
    
    private var networkOptions: ClickstreamNetworkOptions
    private var reachability: NetworkReachability
    private let networkService: NetworkService
    private let performQueue: SerialQueue
    private var deviceStatus: DefaultDeviceStatus
    private let appStateNotifier: AppStateNotifierService
    private var terminationCountDown: DispatchSourceTimer?
    private var networkServiceState: ConnectableState = .disconnected
    private var persistence: DefaultDatabaseDAO<EventRequest>
    private var retryTimer: DispatchSourceTimer?
    private var identifiers: CourierIdentifiers?
    
    #if ETE_TEST_SUITE_ENABLED
    lazy var testMode: Bool = {
        return ProcessInfo.processInfo.arguments.contains("testMode")
    }()
    #endif
    
    private lazy var retryFallbackDelay: TimeInterval = {
        networkOptions.courierHttpFallbackDelayMs / 1000
    }()
    
    var isAvailble: Bool {
        
        let isReachable = reachability.isAvailable
        let isConnected = networkService.isConnected
        let isOnLowPower = deviceStatus.isDeviceLowOnPower
        
        #if TRACKER_ENABLED
        if !isReachable && Tracker.debugMode {
            let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchTriggerFailed,
                                                  reason: FailureReason.networkUnavailable.rawValue)
            Tracker.sharedInstance?.record(event: healthEvent)
        }
        
        if !isConnected && Tracker.debugMode {
            if !isConnected && Tracker.debugMode {
                if isOnLowPower {
                    let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchTriggerFailed,
                                                          reason: FailureReason.lowBattery.rawValue)
                    Tracker.sharedInstance?.record(event: healthEvent)
                } else {
                    let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchTriggerFailed,
                                                          reason: FailureReason.socket_not_open.rawValue)
                    Tracker.sharedInstance?.record(event: healthEvent)
                }
            } else {
                let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchTriggerFailed,
                                                      reason: FailureReason.socket_not_open.rawValue)
                Tracker.sharedInstance?.record(event: healthEvent)
            }
        }
        
        if isOnLowPower && Tracker.debugMode {
            let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchTriggerFailed,
                                                  reason: FailureReason.lowBattery.rawValue)
            Tracker.sharedInstance?.record(event: healthEvent)
        }
        #endif
        return isReachable && isConnected && !isOnLowPower
    }
    
    init(networkOptions: ClickstreamNetworkOptions,
         networkService: NetworkService,
         reachability: NetworkReachability,
         deviceStatus: DefaultDeviceStatus,
         appStateNotifier: AppStateNotifierService,
         performOnQueue: SerialQueue,
         persistence: DefaultDatabaseDAO<EventRequest>) {
        self.networkOptions = networkOptions
        self.networkService = networkService
        self.reachability = reachability
        self.performQueue = performOnQueue
        self.deviceStatus = deviceStatus
        self.appStateNotifier = appStateNotifier
        self.persistence = persistence
        
        self.observeNetworkConnectivity()
        self.observeDeviceStatus()
        self.observeAppStateChanges()
    }
    
    /// Adding a subscription to the app state changes.
    private func observeAppStateChanges() {
        appStateNotifier.start { [weak self] (stateNotification) in guard let checkedSelf = self else { return }
            switch stateNotification {
            case .willResignActive:
                checkedSelf.prepareForTerminatingConnection()
            case .didBecomeActive:
                checkedSelf.cancelTerminationCountDown()
                checkedSelf.establishConnection()
            default:
                break
            }
        }
    }
        
    private func observeNetworkConnectivity() {
        do {
            reachability.whenReachable = { [weak self] (_) in
                guard let checkedSelf = self else { return }
                checkedSelf.establishConnection()
            }
            reachability.whenUnreachable = { [weak self] (_) in
                guard let checkedSelf = self else { return }
                checkedSelf.terminateConnection()
            }
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    private func observeDeviceStatus() {
        deviceStatus.startTracking()
        deviceStatus.onBatteryStatusChanged = { [weak self] isLowOnPower in
            guard let checkedSelf = self else { return }
            /* If network is not connected and the device was on low power,
               now device is on charging state so establish the connection */
            if !checkedSelf.networkService.isConnected && !isLowOnPower {
                checkedSelf.establishConnection()
                // If network is connected but device is on low power, terminate the connection
            } else if checkedSelf.networkService.isConnected && isLowOnPower {
                checkedSelf.terminateConnection()
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

extension CourierRetryMechanism {
    
    func trackBatch(with eventRequest: EventRequest) {
        // add the batch to the cache before sending the batch to the network.
        let startTime = Date()  // Used to calculate batch latency
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
                    // Handle Racoon EventResponse
                    checkedSelf.handleRacoonEventResponse(with: eventRequest, startTime: startTime, response: response)
                case .failure(let error):
                    print("Error: \(error.localizedDescription) for eventRequest guid \(eventRequest.guid)", .verbose)
                    #if TRACKER_ENABLED
                    let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchErrorResponse,
                                                          eventBatchGUID: eventRequest.guid, // eventRequest.guid is the batch GUID
                                                          reason: error.localizedDescription,
                                                          eventCount: eventRequest.eventCount)
                    Tracker.sharedInstance?.record(event: healthEvent)
                    #if ETE_TEST_SUITE_ENABLED
                    Clickstream.ackEvent = AckEventDetails(guid: eventRequest.guid, status: "\(error)")
                    #endif
                    #endif
                }
                #if ETE_TEST_SUITE_ENABLED
                if self?.testMode ?? false {
                    FileManagerOverride.writeToFile()
                }
                #endif
            }
        }
    }
    
    
    func trackBatchFallbackHTTP(with eventRequest: EventRequest) {
        // add the batch to the cache before sending the batch to the network.
        let startTime = Date()

        performQueue.async(flags: .barrier) { [weak self] in
            guard let checkedSelf = self, let courierNetworkService = checkedSelf.networkService as? CourierNetworkService<DefaultCourierHandler> else {
                return
            }

            Task {
                do {
                    let response = try await courierNetworkService.executeHTTPRequest()
                    checkedSelf.handleRacoonEventResponse(with: eventRequest, startTime: startTime, response: response)
                } catch(let error) {
                    print("Error: \(error.localizedDescription) for eventRequest guid \(eventRequest.guid)", .verbose)
                    #if TRACKER_ENABLED
                    let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchErrorResponse,
                                                          eventBatchGUID: eventRequest.guid, // eventRequest.guid is the batch GUID
                                                          reason: error.localizedDescription,
                                                          eventCount: eventRequest.eventCount)
                    Tracker.sharedInstance?.record(event: healthEvent)
                    #if ETE_TEST_SUITE_ENABLED
                    Clickstream.ackEvent = AckEventDetails(guid: eventRequest.guid, status: "\(error)")
                    #endif
                    #endif
                }
            }
        }
    }
    
    private func handleRacoonEventResponse(with eventRequest: EventRequest, startTime: Date, response: Odpf_Raccoon_EventResponse) {
        if response.status == .success && response.code == .ok {
            if let guid = response.data["req_guid"] {
                // remove the delivered batch from the cache.
                removeFromCache(with: guid)
                
                #if ETE_TEST_SUITE_ENABLED
                Clickstream.ackEvent = AckEventDetails(guid: guid, status: "Success")
                #endif
                if let eventType = eventRequest.eventType, !(eventType == .internalEvent) {
                    trackHealthAndPerformanceEvents(eventRequest: eventRequest, startTime: startTime)
                }
                #if EVENT_VISUALIZER_ENABLED
                /// Update status of the event batch to acknowledged from network
                /// to check if the delegate is connected, if not no event should be sent to client
                if let stateViewer = Clickstream._stateViewer {
                    /// Updating the event state to acknowledged based on eventBatchGuid.
                    /// The eventBatchID passed in NetworkBuilder would be used to map events and
                    /// then update the state respectively.
                    stateViewer.updateStatus(eventBatchID: guid, state: .ackReceived)
                }
                print("RetryMechanism, received response for batch with id: \(response.data)")
                #endif
            }
        } else {
            if response.code == .maxConnectionLimitReached {
                #if TRACKER_ENABLED
                if Tracker.debugMode {
                    let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamConnectionFailure,
                                                          reason: FailureReason.MAX_CONNECTION_LIMIT_REACHED.rawValue)
                    Tracker.sharedInstance?.record(event: healthEvent)
                }
                #endif
                terminateConnection()
                establishConnection()
                #if ETE_TEST_SUITE_ENABLED
                Clickstream.ackEvent = AckEventDetails(guid: eventRequest.guid, status: "Max Connection Limit Reached")
                #endif
            }
            #if TRACKER_ENABLED
            if response.code == .maxUserLimitReached {
               let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamConnectionFailure,
                                                     reason: FailureReason.MAX_USER_LIMIT_REACHED.rawValue)
                Tracker.sharedInstance?.record(event: healthEvent)
                #if ETE_TEST_SUITE_ENABLED
                Clickstream.ackEvent = AckEventDetails(guid: eventRequest.guid, status: "Max User Limit Reached")
                #endif
            }
            
            if response.code == .badRequest {
                print("Error: Parsing Exception for eventRequest guid \(eventRequest.guid)", .verbose)
                if Tracker.debugMode {
                    var healthEvent: HealthAnalysisEvent!
                    healthEvent = HealthAnalysisEvent(eventName: .ClickstreamWriteToSocketFailed,
                                                      eventBatchGUID: eventRequest.guid,
                                                      reason: FailureReason.ParsingException.rawValue,
                                                      eventCount: eventRequest.eventCount)
                    Tracker.sharedInstance?.record(event: healthEvent)
                    #if ETE_TEST_SUITE_ENABLED
                    Clickstream.ackEvent = AckEventDetails(guid: eventRequest.guid, status: "Bad Request")
                    #endif
                }
            }
            #endif
        }
    }

    func openConnectionForcefully() {
        establishConnection(keepTrying: true)
    }
    
    func stopTracking() {
        appStateNotifier.stop()
        deviceStatus.stopTracking()
        reachability.stopNotifier()
        terminateConnection()
    }

    func configureIdentifiers(_ identifiers: CourierIdentifiers) {
        self.identifiers = identifiers
        establishConnection()
    }
}

extension CourierRetryMechanism {
    
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
        Clickstream.connectionState = .closing
        terminationCountDown = DispatchSource.makeTimerSource(flags: .strict, queue: performQueue)
        // This gives the breathing space for flushing the events.
        terminationCountDown?.schedule(deadline: .now() + Clickstream.configurations.connectionTerminationTimerWaitTime)
        terminationCountDown?.setEventHandler(handler: { [weak self] in guard let checkedSelf = self else { return }
            checkedSelf.terminateConnection()
        })
        terminationCountDown?.resume()
    }
    
    private func establishConnection(keepTrying: Bool = false) {
        guard let identifiers else {
            return
        }

        /// Resetting value of Clickstream.connectionState to .connected which had been changed
        /// to .closing in line 261 when app was moving to background
        if Clickstream.updateConnectionStatus && self.networkService.isConnected {
            Clickstream.connectionState = .connected
        }

        if self.networkService.isConnected || !reachability.isAvailable {
            return
        }

        Task {
            await networkService.initiateSecondaryConnection(connectionStatusListener: { [weak self] result in
                guard let checkedSelf = self else {
                    return
                }

                NotificationCenter.default.post(name: Constants.CourierConnectionNotification,
                                                object: [Constants.Strings.didConnect: checkedSelf.networkService.isConnected])

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
            }, keepTrying: keepTrying, identifiers: identifiers)
        }
    }
}

extension CourierRetryMechanism {
    
    private func addToCache(with eventRequest: EventRequest) {
        if var fetchedEventRequest = persistence.fetchOne(eventRequest.guid) {
            if fetchedEventRequest.retriesMade >= Clickstream.configurations.maxRetriesPerBatch {
                persistence.deleteOne(eventRequest.guid)
                #if TRACKER_ENABLED
                if Tracker.debugMode {
                    let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchDropped,
                                                          eventBatchGUID: fetchedEventRequest.guid,
                                                          eventCount: eventRequest.eventCount)
                    Tracker.sharedInstance?.record(event: healthEvent)
                }
                #endif
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
        retryTimer?.schedule(deadline: .now() + retryFallbackDelay,
                             repeating: Clickstream.configurations.maxRequestAckTimeout)
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
        guard isAvailble else {
            stopObservingFailedBatches()
            return
        }
        
        if let failedRequests = persistence.fetchAll(), !failedRequests.isEmpty {
            let date = Date()
            let timedOutRequests = failedRequests.filter {
                (date.timeIntervalSince1970 - $0.timeStamp.timeIntervalSince1970) >= retryFallbackDelay
            }
            
            // If no timedOut requests are found then do nothing and return.
            if timedOutRequests.isEmpty {
                return
            }
            
            let retryCoefficient = (Clickstream.configurations.maxRequestAckTimeout/Double(timedOutRequests.count))/2
            for (index,batch) in timedOutRequests.enumerated() {
                var _batch = batch
                performQueue.asyncAfter(deadline: .now() + (retryCoefficient * Double(index))) { [weak self] in
                    guard let checkedSelf = self else {
                        return
                    }
                    
                    do {
                        // Refresh the timeStamp before sending the batch!
                        try _batch.refreshBatchSentTimeStamp()
                        checkedSelf.trackBatch(with: _batch)
                    } catch {
                        checkedSelf.trackBatchFallbackHTTP(with: _batch)
                        print("Failed to update batch time on retry. Description: \(error)",.critical)
                    }
                }
            }
        }
    }
}

// MARK: - Track Clickstream health.
extension CourierRetryMechanism {
    
    func trackHealthAndPerformanceEvents(eventRequest: EventRequest, startTime: Date) {
        #if TRACKER_ENABLED
        if Tracker.debugMode {
            guard eventRequest.eventType != Constants.EventType.instant else { return }
            
            let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchSuccessAck,
                                                  eventBatchGUID: eventRequest.guid,
                                                  eventCount: eventRequest.eventCount)
            Tracker.sharedInstance?.record(event: healthEvent)
            
        }
        #endif
    }
}

