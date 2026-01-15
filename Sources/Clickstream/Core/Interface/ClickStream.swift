//
//  Clickstream.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//
import Foundation
import SwiftProtobuf

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
    
    /// Holds the configurations for the sdk.
    internal static var configurations: ClickstreamConstraints = ClickstreamConstraints()
    internal static var courierConfigurations: ClickstreamCourierConstraints = ClickstreamCourierConstraints()

    /// Holds the event classification for the sdk.
    internal static var eventClassifier: ClickstreamEventClassification = ClickstreamEventClassification()

    
    /// Clickstream shared instance.
    private static var sharedInstance: Clickstream?
    
    private var dependencies: DefaultClickstreamDependencies?
    #if EVENT_VISUALIZER_ENABLED
    /// internal stored static variable which is a delegate
    /// to sent the events to client for visualization.
    /// If delegate is nil then no events are passed to client.
    internal weak static var _stateViewer: EventStateViewable?
    
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
    #if ETE_TEST_SUITE_ENABLED
    internal static var ackEvent: AckEventDetails?
    #endif
    
    /// Public property to get Clickstream connection state
    public var clickstreamConnectionState: Clickstream.ConnectionState? {
        return Clickstream.connectionState
    }
    
    /// ClickstreamDelegate.
    private weak var delegate: ClickstreamDelegate?
    
    // MARK: - Building blocks of the SDK.
    private let socketNetworkBuilder: any NetworkBuildable
    private let courierNetworkBuilder: any NetworkBuildable

    private let socketEventProcessor: EventProcessor
    private let courierEventProcessor: EventProcessor

    private let socketEventWarehouser: any EventWarehouser
    private let courierEventWarehouser: any EventWarehouser
    
    /// Private initialiser for the Clickstream Interface.
    /// - Parameters:
    ///   - networkBuilder: network builder instance
    ///   - eventWarehouser: event warehouser instance
    ///   - eventProcessor: event processor instance
    ///   - dataSource: dataSource for Clickstream
    private init(socketNetworkBuilder: any NetworkBuildable,
                 courierNetworkBuilder: any NetworkBuildable,
                 socketEventWarehouser: any EventWarehouser,
                 courierEventWarehouser: any EventWarehouser,
                 socketEventProcessor: EventProcessor,
                 courierEventProcessor: EventProcessor,
                 delegate: ClickstreamDelegate? = nil) {

        self.socketNetworkBuilder = socketNetworkBuilder
        self.courierNetworkBuilder = courierNetworkBuilder

        self.socketEventWarehouser = socketEventWarehouser
        self.courierEventWarehouser = courierEventWarehouser

        self.socketEventProcessor = socketEventProcessor
        self.courierEventProcessor = courierEventProcessor

        self.delegate = delegate
    }
    
    static var updateConnectionStatus: Bool = false
    
    static var timerCrashFixFlag: Bool = false
    
    static var priorityEventsEnabled: Bool = false
    
    /// Use this property to pass application name without any space or special characters.
    static var appPrefix: String = ""
    
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
        sharedInstance?.socketEventWarehouser.stop()
        sharedInstance?.courierEventWarehouser.stop()
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
        socketEventProcessor.createEvent(event: event)
        courierEventProcessor.createEvent(event: event)
    }

    /// Tracks Clickstream event via websocket network channel
    /// - Parameter event: Client's Clickstream Event
    public func trackEventViaWebsocket(with event: ClickstreamEvent) {
        socketEventProcessor.createEvent(event: event)
    }

    /// Tracks Clickstream event via courier network channel
    /// - Parameter event: Client's Clickstream Event
    public func trackEventViaCourier(with event: ClickstreamEvent) {
        courierEventProcessor.createEvent(event: event)
    }
    
    /// Initializes an instance of the API with the given configurations.
    /// Returns a new Clickstream instance API object. This allows you to create one instance only.
    /// - Parameters:
    ///   - networkConfiguration: Network Configurations needed for connecting socket
    ///   - constraints: Clickstream constraints passed from the integrating app.
    ///   - dataSource: ClickstreamDataSource instance passed from the integrating app.
    ///   - eventClassification: Clickstream event classification passed from the integrating app.
    ///   - request: URL request with secret code for the services to authenticate.
    ///   - appPrefix: Application name without any space or special characters that needs
    ///   to be passed from integrating app.
    /// - Returns: returns a Clickstream instance to keep throughout the project.
    ///            You can always get the instance by calling getInstance()
    #if TRACKER_ENABLED
    @discardableResult public static func initialise(with request: URLRequest,
                                                     configurations: ClickstreamConstraints,
                                                     courierConfigurations: ClickstreamCourierConstraints,
                                                     eventClassification: ClickstreamEventClassification,
                                                     delegate: ClickstreamDelegate? = nil,
                                                     updateConnectionStatus: Bool = false,
                                                     timerCrashFixFlag: Bool = false,
                                                     priorityEventsEnabled: Bool = false,
                                                     appPrefix: String,
                                                     samplerConfiguration: EventSamplerConfiguration? = nil,
                                                     networkOptions: ClickstreamNetworkOptions) throws -> Clickstream? {
        do {
            return try initializeClickstream(
                with: request,
                configurations: configurations,
                courierConfigurations: courierConfigurations,
                eventClassification: eventClassification,
                delegate: delegate,
                updateConnectionStatus: updateConnectionStatus,
                timerCrashFixFlag: timerCrashFixFlag,
                priorityEventsEnabled: priorityEventsEnabled,
                appPrefix: appPrefix,
                samplerConfiguration: samplerConfiguration,
                networkOptions: networkOptions)
        } catch {
            print("Cannot initialise Clickstream. Dependencies could not be initialised.",.critical)
            // Relay the database error.
            throw Clickstream.ClickstreamError.initialisation(error.localizedDescription)
        }
    }
    #else
    @discardableResult public static func initialise(with request: URLRequest,
                                                     configurations: ClickstreamConstraints,
                                                     courierConfigurations: ClickstreamCourierConstraints,
                                                     eventClassification: ClickstreamEventClassification,
                                                     delegate: ClickstreamDelegate? = nil,
                                                     updateConnectionStatus: Bool = false,
                                                     timerCrashFixFlag: Bool = false,
                                                     appPrefix: String,
                                                     samplerConfiguration: EventSamplerConfiguration? = nil,
                                                     networkOptions: ClickstreamNetworkOptions) throws -> Clickstream? {
        do {
            return try initializeClickstream(
                with: request,
                configurations: configurations,
                courierConfigurations: courierConfigurations,
                eventClassification: eventClassification,
                delegate: delegate,
                updateConnectionStatus: updateConnectionStatus,
                timerCrashFixFlag: timerCrashFixFlag,
                appPrefix: appPrefix,
                samplerConfiguration: samplerConfiguration,
                networkOptions: networkOptions)
        } catch {
            print("Cannot initialise Clickstream. Dependencies could not be initialised.",.critical)
            // Relay the database error.
            throw Clickstream.ClickstreamError.initialisation(error.localizedDescription)
        }
    }
    #endif
    
    static func initializeClickstream(with request: URLRequest,
                                      configurations: ClickstreamConstraints,
                                      courierConfigurations: ClickstreamCourierConstraints,
                                      eventClassification: ClickstreamEventClassification,
                                      delegate: ClickstreamDelegate? = nil,
                                      updateConnectionStatus: Bool = false,
                                      timerCrashFixFlag: Bool = false,
                                      priorityEventsEnabled: Bool = false,
                                      appPrefix: String,
                                      samplerConfiguration: EventSamplerConfiguration? = nil,
                                      networkOptions: ClickstreamNetworkOptions) throws -> Clickstream? {

        let semaphore = DispatchSemaphore(value: 1)
        defer {
            semaphore.signal()
        }
        semaphore.wait()
        
        guard sharedInstance != nil else {
            
            // Assign the configurations.
            Clickstream.configurations = configurations
            Clickstream.courierConfigurations = courierConfigurations
            Clickstream.eventClassifier = eventClassification
            Clickstream.updateConnectionStatus = updateConnectionStatus
            Clickstream.timerCrashFixFlag = timerCrashFixFlag
            Clickstream.priorityEventsEnabled = priorityEventsEnabled
            Clickstream.appPrefix = appPrefix.lowercased().replacingOccurrences(of: " ", with: "")
            
            // All the dependency injections pertaining to the clickstream blocks happen here!
            // Load default dependencies.
            do {
                let dependencies = try DefaultClickstreamDependencies(with: request,
                                                                      samplerConfiguration: samplerConfiguration,
                                                                      networkOptions: networkOptions)

                sharedInstance = Clickstream(socketNetworkBuilder: dependencies.socketNetworkBuilder,
                                             courierNetworkBuilder: dependencies.courierNetworkBuilder,
                                             socketEventWarehouser: dependencies.socketEventWarehouser,
                                             courierEventWarehouser: dependencies.courierEventWarehouser,
                                             socketEventProcessor: dependencies.socketEventProcessor,
                                             courierEventProcessor: dependencies.courierEventProcessor,
                                             delegate: delegate)

                sharedInstance?.dependencies = dependencies
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

@propertyWrapper
struct AtomicConnectionState {
    private let dispatchQueue = DispatchQueue(label: Constants.QueueIdentifiers.atomicAccess.rawValue, attributes: .concurrent)
    private var state: Clickstream.ConnectionState = .closed
    var wrappedValue: Clickstream.ConnectionState {
        get { dispatchQueue.sync { state } }
        set { dispatchQueue.sync(flags: .barrier) { state = newValue } }
    }
}

// MARK: - Code below here is support for the Clickstream's EventVisualizer.
#if EVENT_VISUALIZER_ENABLED
extension Clickstream {
    
    /// Initialise event visualizer state tracking
    /// - Parameters:
    ///   - guid:String
    ///   - eventTimestamp:String
    ///   - storageGuid:String
    ///   - storageEventTimestamp:String
    public func setEventVisualizerStateTracking(eventGuid: String,
                                                eventTimestamp: String) {
        Constants.EventVisualizer.eventGuid = eventGuid
        Constants.EventVisualizer.guid = eventGuid
        Constants.EventVisualizer.eventTimestamp = eventTimestamp
        Constants.EventVisualizer.deviceTimestamp = eventTimestamp
    }
}
#endif

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
        Tracker.initialise(commonProperties: commonProperties, healthTrackingConfigs: configs, dataSource: dataSource, delegate: delegate)
    }
    
    public func getTracker() -> Tracker? {
        return Tracker.sharedInstance
    }
}
#endif

extension Clickstream {

    /// Courier client's user credentials provider
    /// - Parameter identifiers: A client's credentials
    public func provideClientIdentifiers(with identifiers: ClickstreamClientIdentifiers,
                                         topic: String,
                                         courierConnectOptionsObserver:  CourierConnectOptionsObserver?) {

        dependencies?.provideCourierClientIdentifiers(with: identifiers, topic: topic, courierConnectOptionsObserver: courierConnectOptionsObserver)
    }

    public func removeClientIdentifiers() {
        dependencies?.removeCourierClientIdentifiers()
    }
}
