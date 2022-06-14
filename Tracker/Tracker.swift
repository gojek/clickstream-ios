//
//  Tracker.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 26/08/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

/// Conform to this delegate to receive health events at client app.
public protocol TrackerDelegate: AnyObject {
    func getHealthEvent(event: HealthTrackerDTO)
}

/// Conform to this data source to send the current user location details to Clcikstream SDK
public protocol TrackerDataSource {
    
    /// Returns the current user location as `CSLocation` instance.
    /// - Returns: `CSLocation` instance.
    func currentUserLocation() -> CSLocation?
}

protocol AnalysisEvent { }

public final class Tracker {
    
    private(set) var healthTracker: HealthTracker
    
    static var sharedInstance: Tracker?
    
    // Holds the health tracking configs for the SDK
    internal static var healthTrackingConfigs: ClickstreamHealthConfigurations!
    
    /// readonly public accessor for CSCommonProperties
    internal var commonProperties: CSCommonProperties?
    
    /// Tells whether the debugMode is enabled or not.
    internal static var debugMode: Bool = false
    
    var location: CSLocation?
    
    private static let queue = SerialQueue(label: Constants.QueueIdentifiers.tracker.rawValue, qos: .utility)
    private var appStateNotifier: AppStateNotifierService
    private let database: Database
    
    /// ClickstreamDelegate.
    internal private(set) var delegate: TrackerDelegate

    /// ClickStreamDataSource.
    private var _dataSource: TrackerDataSource
    
    /// readonly public accessor for dataSource.
    public var dataSource: TrackerDataSource {
        get {
            return _dataSource
        }
    }
    
    init(appStateNotifier: AppStateNotifierService,
         db: Database,
         dataSource: TrackerDataSource, delegate: TrackerDelegate) {
        self.database = db
        self.appStateNotifier = appStateNotifier
        self.healthTracker = HealthTracker(performOnQueue: Tracker.queue,
                                           db: database)
        self._dataSource = dataSource
        self.delegate = delegate
        self.observeAppStateChanges()
        self.flushOnAppUpgrade()
    }
    
    @discardableResult
    static func initialise(commonProperties: CSCommonProperties, healthTrackingConfigs: ClickstreamHealthConfigurations,
                           dataSource: TrackerDataSource, delegate: TrackerDelegate) -> Tracker? {
        
        Tracker.healthTrackingConfigs = healthTrackingConfigs
        
        Tracker.debugMode = healthTrackingConfigs.debugMode(userID: commonProperties.customer.identity,
                                                            currentAppVersion: commonProperties.app.version)
        
        if Tracker.debugMode {
            guard let instance = self.sharedInstance else {
                // Create a separate db for health and perf events.
                var db: Database
                do {
                    db = try DefaultDatabase()
                } catch {
                    return nil
                }
                
                sharedInstance = Tracker(appStateNotifier: DefaultAppStateNotifierService(with: queue),
                                         db: db, dataSource: dataSource, delegate: delegate)
                sharedInstance?.commonProperties = commonProperties
                return sharedInstance
            }
            return instance
        }
        return nil
    }
    
    func record(event: AnalysisEvent?) {
        if let event = event as? HealthAnalysisEvent {
            self.healthTracker.record(event: event)
        }
    }
    
    /// Adding a subscription to the app state changes.
    private func observeAppStateChanges() {
        appStateNotifier.start { [weak self] (stateNotification) in guard let checkedSelf = self else { return }
            switch stateNotification {
            case .willTerminate, .didEnterBackground:
                if Tracker.healthTrackingConfigs.trackedVia == .external || Tracker.healthTrackingConfigs.trackedVia == .both {
                    checkedSelf.healthTracker.flushErrorEvents()
                }
            default:
                break
            }
        }
    }
    
    func getEvents() -> [Event]? {
        guard Tracker.healthTrackingConfigs.trackedVia == .internal || Tracker.healthTrackingConfigs.trackedVia == .both else { return nil }
           
        var events = [Event]()
        
        // get the health events which need to be send to CS
        guard let eventsToBeFlushed = healthTracker.flushFunnelEvents() else { return nil }
        guard let commonProperties = commonProperties else { return nil }
        
        let metaData = Gojek_Clickstream_Internal_HealthMeta.with {
            $0.device = commonProperties.device.proto
            $0.customer = commonProperties.customer.proto
            $0.session = commonProperties.session.proto
            $0.app = commonProperties.app.proto
            if let location =  location?.proto { // If the user's enabled the location only then send the location.
                $0.location = location
            }
        }
        
        // Get instant health events
        let instantEvents = eventsToBeFlushed.filter { $0.eventType == TrackerConstant.EventType.instant }
        events.append(contentsOf: getInstantEvents(instantEvents: instantEvents, metaData: metaData))
        
        // Get aggregated health events
        let aggregatedEvents = eventsToBeFlushed.filter { $0.eventType == TrackerConstant.EventType.aggregate }
        events.append(contentsOf: getAggregatedEvents(aggregatedEvents: aggregatedEvents, metaData: metaData))
        
        return events
    }
    
    private func getInstantEvents(instantEvents: [HealthAnalysisEvent], metaData: Gojek_Clickstream_Internal_HealthMeta) -> [Event] {
        var events = [Event]()
        for event in instantEvents {
            let eventGuid = UUID().uuidString
            
            let healthEvent = Gojek_Clickstream_Internal_Health.with {
                $0.eventName = event.eventName.rawValue
                $0.numberOfEvents = 1 // Since instant events are fired one at a time
                $0.healthMeta = metaData
                $0.healthMeta.eventGuid = eventGuid
                
                $0.healthDetails = Gojek_Clickstream_Internal_HealthDetails.with {
                    if let eventGUID = event.eventGUID {
                        $0.eventGuids = [eventGUID]
                    }
                    
                    if let eventBatchGUID = event.eventBatchGUID {
                        $0.eventBatchGuids = [eventBatchGUID]
                    }
                }
                
                if let timeToConnection = event.timeToConnection {
                    $0.traceDetails = Gojek_Clickstream_Internal_TraceDetails.with {
                        $0.timeToConnection = timeToConnection
                        
                        $0.errorDetails = Gojek_Clickstream_Internal_ErrorDetails.with {
                            $0.reason = event.reason ?? ""
                        }
                    }
                }
                $0.errorDetails = Gojek_Clickstream_Internal_ErrorDetails.with {
                    $0.reason = event.reason ?? ""
                }
            }
            
            if let event = constructEvent(healthEvent: healthEvent, eventGuid: eventGuid) {
                events.append(event)
            }
        }
        return events
    }
    
    private func getAggregatedEvents(aggregatedEvents: [HealthAnalysisEvent], metaData: Gojek_Clickstream_Internal_HealthMeta) -> [Event] {
        var events = [Event]()
        let groupingDictionary = Dictionary(grouping: aggregatedEvents, by: { $0.eventName })
        for (key, eventNameBasedAggregation) in groupingDictionary {
            let eventGuid = UUID().uuidString
            var eventGuids = eventNameBasedAggregation.compactMap { $0.eventGUID }
            if eventGuids.isEmpty {
                eventNameBasedAggregation.forEach {
                    if let _events = $0.events, !_events.isEmpty {
                        eventGuids.append(contentsOf: _events.components(separatedBy: ", "))
                    }
                }
            }
            
            let eventBatchGuids = eventNameBasedAggregation.compactMap { $0.eventBatchGUID }
            
            var healthEvent = Gojek_Clickstream_Internal_Health.with {
                $0.numberOfEvents = Int64(eventGuids.count)
                $0.numberOfBatches = Int64(eventBatchGuids.count)
                $0.healthMeta = metaData
                $0.healthMeta.eventGuid = eventGuid
                
                let currentTimestamp = Date()
                $0.eventTimestamp = Google_Protobuf_Timestamp(date: currentTimestamp)
                $0.eventName = key.rawValue
                $0.deviceTimestamp = Google_Protobuf_Timestamp(date: Date())
            }
            
            let healthEventDetails = Gojek_Clickstream_Internal_HealthDetails.with {
                $0.eventGuids = eventGuids
                $0.eventBatchGuids = eventBatchGuids
            }
            healthEvent.healthDetails = healthEventDetails
            
            if let event = constructEvent(healthEvent: healthEvent, eventGuid: eventGuid) {
                events.append(event)
            }
        }
        return events
    }
    
    /// Construct event
    /// - Parameters:
    ///   - healthEvent: Gojek_Clickstream_Internal_Health
    ///   - eventGuid: Health meta guid
    /// - Returns: Event
    private func constructEvent(healthEvent: Gojek_Clickstream_Internal_Health, eventGuid: String) -> Event? {
        do {
            // Constructing the Gojek_Clickstream_De_Event
            let eventProto = try Odpf_Raccoon_Event.with {
                $0.eventBytes = try healthEvent.serializedData()
                if let typeOfEvent = type(of: healthEvent).protoMessageName.components(separatedBy: ".").last {
                    $0.type = typeOfEvent.lowercased()
                }
            }
            let event = try Event(guid: eventGuid,
                                  timestamp: Date(),
                                  type: TrackerConstant.HealthEventType,
                                  eventProtoData: eventProto.serializedData())
            return event
        } catch {
            return nil
        }
    }
    
    /// Flushes health events, being tracked via Clickstream, in case of an app upgrade.
    private func flushOnAppUpgrade() {
        Tracker.queue.async { [weak self] in guard let checkedSelf = self else { return }
            let appVersionChecker = DefaultAppVersionChecker(currentAppVersion: checkedSelf.commonProperties?.app.version)
            if appVersionChecker.hasAppVersionChanged() {
                // Delete health events being tracked via Clickstream
                checkedSelf.healthTracker.flushFunnelEvents()
            }
        }
    }
    
    static func destroy() {
        sharedInstance = nil
    }
    
    /// Update common properties needed for Tracker
    /// - Parameter commonProperties: CSCommonProperties
    public func updateCommonProperties(commonProperties: CSCommonProperties) {
        self.commonProperties = commonProperties
    }
}
