//
//  Clickstream.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//
import Foundation
import SwiftProtobuf

/// Conform to this delegate to set NTP Time.
public protocol ClickstreamDataSource: AnyObject {
    
    /// Returns NTP timestamp
    /// - Returns: NTP Date() instance
    func currentNTPTimestamp() -> Date?
}

public protocol ClickstreamDelegate: AnyObject {
    
    /// Provides Clickstream connection state changes
    /// - Parameter state: Clickstream.ConnectionState
    func onConnectionStateChanged(state: Clickstream.ConnectionState)
}

/// Primary class for integrating Clickstream.
public final class Clickstream {
    
    /// States the various states of Clicstream connection
    public enum ConnectionState {
        // When the socket is trying to connect
        case connecting
        // When the socket is about to be closed. can be called when the app moves to backgroud
        case closing
        // When the socket connection is closed
        case closed
        // When the socket connection is fails
        case failed
        // When the socket connection gets connected
        case connected
    }
    
    public enum ClickstreamError: Error, LocalizedError {
        /// Clickstream could not be initialised.
        case initialisation(String)
        
        public var errorDescription: String? {
            switch self {
            case .initialisation(let message):
                return NSLocalizedString("Clickstream initialisation error: \(message)", comment: "initialisation error")
            }
        }
    }
    
    /// Tells whether the clickstream is initialised on background queue or not.
    /// Temporary handling. Will be replaced by an experimentation module within Clickstream.
    internal static var isInitialisedOnBackgroundQueue: Bool = false
    
    /// Holds the constraints for the sdk.
    internal static var constraints: ClickstreamConstraints = ClickstreamConstraints()
    
    /// Holds the event classification for the sdk.
    internal static var eventClassifier: ClickstreamEventClassification = ClickstreamEventClassification()
    
    /// Clickstream shared instance.
    private static var sharedInstance: Clickstream?
    
    private var dependencies: DefaultClickstreamDependencies?
    
    #if EVENT_VISUALIZER_ENABLED
    /// internal stored static variable which is a delegate
    /// to sent the events to client for visualization.
    /// If delegate is nil then no events are passed to client.
    internal static var _stateViewer: EventStateViewable?
    
    /// computed public property which sets
    /// and fetches the global `_stateViewer` variable
    public var stateViewer: EventStateViewable? {
        get {
            return Clickstream._stateViewer
        }
        set {
            Clickstream._stateViewer = newValue
        }
    }
    #endif
    
    /// ClickstreamDelegate.
    private weak var delegate: ClickstreamDelegate?
    
    /// ClickstreamDataSource.
    private weak var _dataSource: ClickstreamDataSource?
    
    /// readonly public accessor for dataSource.
    public weak var dataSource: ClickstreamDataSource? {
        get {
            return _dataSource
        }
    }
    
    /// Holds latest NTP date
    internal static var currentNTPTimestamp: Date? {
        get {
            let timestamp = sharedInstance?._dataSource?.currentNTPTimestamp()
            return timestamp
        }
    }
    
    // MARK: - Building blocks of the SDK.
    private let networkBuilder: NetworkBuildable
    private let eventProcessor: EventProcessor
    private let eventWarehouser: EventWarehouser
    
    /// Private initialiser for the Clickstream Interface.
    /// - Parameters:
    ///   - networkBuilder: network builder instance
    ///   - eventWarehouser: event warehouser instance
    ///   - eventProcessor: event processor instance
    ///   - dataSource: dataSource for Clickstream
    private init(networkBuilder: NetworkBuildable,
                 eventWarehouser: EventWarehouser,
                 eventProcessor: EventProcessor,
                 dataSource: ClickstreamDataSource,
                 delegate: ClickstreamDelegate? = nil) {
        self.networkBuilder = networkBuilder
        self.eventWarehouser = eventWarehouser
        self.eventProcessor = eventProcessor
        self._dataSource = dataSource
        self.delegate = delegate
    }
    
    /// Returns the shared Clickstream instance.
    /// - Returns: `Clickstream` instance.
    public static func getInstance() -> Clickstream? {
        return sharedInstance
    }
    
    public static func setLogLevel(_ level: Logger.LogLevel) {
        Logger.logLevel = level
    }
    
    /// Provides whether clickstream is connected to the network or not
    public var isClickstreamConnectedToNetwork: Bool {
        get {
            return dependencies?.isSocketConnected ?? false
        }
    }
    
    /// Stops the Clickstream tracking.
    public static func stopTracking() {
        sharedInstance?.eventWarehouser.stop()
    }
    
    /// Destroys the Clickstream instance.
    /// Calls the 'stopTracking' method internally.
    public static func destroy() {
        stopTracking()
        sharedInstance = nil
    }
    
    /// Call this method add an event to tracking.
    /// - Parameter event: readonly public accessor for CSEventDTO
    /// CSEventDTO consists of
    ///     guid:- event guid
    ///     message:- product proto message for an event which needs to be tracked.
    ///     timestamp:- timestamp of the event
    public func trackEvent(with event: ClickstreamEvent) {
        self.eventProcessor.createEvent(event: event)
    }
    
    /// Initializes an instance of the API with the given configurations.
    /// Returns a new Clickstream instance API object. This allows you to create one instance only.
    /// - Parameters:
    ///   - networkConfiguration: Network Configurations needed for connecting socket
    ///   - constraints: Clickstream constraints passed from the integrating app.
    ///   - eventClassification: Clickstream event classification passed from the integrating app.
    /// - Returns: returns a Clickstream instance to keep throughout the project.
    ///            You can always get the instance by calling getInstance()
    @discardableResult public static func initialise(request: URLRequest,
                                                     constraints: ClickstreamConstraints? = nil,
                                                     eventClassification: ClickstreamEventClassification? = nil,
                                                     dataSource: ClickstreamDataSource,
                                                     delegate: ClickstreamDelegate? = nil) throws -> Clickstream? {
        
        let semaphore = DispatchSemaphore(value: 1)
        defer {
            semaphore.signal()
        }
        semaphore.wait()
        
        guard sharedInstance != nil else {
            
            // Setting Constraints to be used for the SDK.
            if let constraints = constraints {
                Clickstream.constraints = constraints
            } else {
                print("Initialising Clickstream using default constraints.",.verbose)
            }
            
            // Setting Event Classification to be used for the SDK.
            if let eventClassifier = eventClassification {
                Clickstream.eventClassifier = eventClassifier
            } else {
                print("Initialising Clickstream using default event classification",.verbose)
            }
            
            // All the dependency injections pertaining to the clickstream blocks happen here!
            // Load default dependencies.
            do {
                let dependencies = try DefaultClickstreamDependencies(with: request)
                sharedInstance = Clickstream(networkBuilder: dependencies.networkBuilder,
                                             eventWarehouser: dependencies.eventWarehouser,
                                             eventProcessor: dependencies.eventProcessor,
                                             dataSource: dataSource,
                                             delegate: delegate)
                sharedInstance?.dependencies = dependencies // saving a copy of dependencies
            } catch {
                print("Cannot initialise Clickstream. Dependencies could not be initialised.",.critical)
                // Relay the database error.
                throw Clickstream.ClickstreamError.initialisation(error.localizedDescription)
            }
            
            return sharedInstance
        }
        return sharedInstance
    }
    
    @AtomicConnectionState internal static var connectionState: Clickstream.ConnectionState {
        didSet {
            sharedInstance?.delegate?.onConnectionStateChanged(state: connectionState)
        }
    }
}

// MARK: - Code below here is support for the Clickstream's Health Tracking.
#if TRACKER_ENABLED
extension Clickstream {
    
    /// Initialise tracker
    /// - Parameters:
    ///   - configs: ClickstreamHealthConfigurations
    ///   - commonProperties: CSCommonProperties
    ///   - dataSource: TrackerDataSource
    ///   - delegate: TrackerDelegate
    public func setTracker(configs: ClickstreamHealthConfigurations,
                           commonProperties: CSCommonProperties,
                           dataSource: TrackerDataSource,
                           delegate: TrackerDelegate) {
        Tracker.initialise(commonProperties: commonProperties, healthTrackingConfigs: configs,dataSource: dataSource, delegate: delegate)
    }
    
    public func getTracker() -> Tracker? {
        return Tracker.sharedInstance
    }
}
#endif

// MARK: - Code below here is support for the Clickstream's EventVisualizer.
#if EVENT_VISUALIZER_ENABLED
extension Clickstream {
    
    /// Initialise event visualizer state tracking
    /// - Parameters:
    ///   - guid:String
    ///   - eventTimestamp:String
    ///   - storageGuid:String
    ///   - storageEventTimestamp:String
    public func setEventVisualizerStateTracking(guid: String,
                                                eventTimestamp: String) {
        Constants.EventVisualizer.guid = guid
        Constants.EventVisualizer.eventTimestamp = eventTimestamp
    }
}
#endif

@propertyWrapper
struct AtomicConnectionState {
    private let dispatchQueue = DispatchQueue(label: Constants.QueueIdentifiers.atomicAccess.rawValue, attributes: .concurrent)
    private var state: Clickstream.ConnectionState = .closed
    var wrappedValue: Clickstream.ConnectionState {
        get { dispatchQueue.sync { state } }
        set { dispatchQueue.sync(flags: .barrier) { state = newValue } }
    }
}
