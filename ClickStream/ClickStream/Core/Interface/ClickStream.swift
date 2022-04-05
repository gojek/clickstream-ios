//
//  ClickStream.swift
//  ClickStream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//
import Foundation
import SwiftProtobuf

/// Primary class for integrating ClickStream.
public final class ClickStream {
    
    public enum ClickStreamError: Error, LocalizedError {
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
    
    /// Tells whether the debugMode is enabled or not.
    internal static var debugMode: Bool = false
    
    /// Holds the constraints for the sdk.
    internal static var constraints: ClickStreamConstraints = ClickStreamConstraints()
    
    /// Holds the event classification for the sdk.
    internal static var eventClassifier: ClickStreamEventClassification = ClickStreamEventClassification()
    
    /// ClickStream shared instance.
    private static var sharedInstance: ClickStream?
    
    // MARK: - Building blocks of the SDK.
    private let networkBuilder: NetworkBuildable
    private let eventProcessor: EventProcessor
    private let eventWarehouser: EventWarehouser
    
    /// Private initialiser for the ClickStream Interface.
    /// - Parameters:
    ///   - networkBuilder: network builder instance
    ///   - eventWarehouser: event warehouser instance
    ///   - eventProcessor: event processor instance
    ///   - dataSource: dataSource for ClickStream
    private init(networkBuilder: NetworkBuildable,
                 eventWarehouser: EventWarehouser,
                 eventProcessor: EventProcessor) {
        self.networkBuilder = networkBuilder
        self.eventWarehouser = eventWarehouser
        self.eventProcessor = eventProcessor
    }
    
    /// Returns the shared ClickStream instance.
    /// - Returns: `ClickStream` instance.
    public static func getInstance() -> ClickStream? {
        return sharedInstance
    }
    
    public static func setLogLevel(_ level: Logger.LogLevel) {
        Logger.logLevel = level
    }
    
    /// Stops the ClickStream tracking.
    public static func stopTracking() {
        sharedInstance?.eventWarehouser.stop()
    }
    
    /// Destroys the ClickStream instance.
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
}

extension ClickStream {
    
    /// Initializes an instance of the API with the given configurations.
    /// Returns a new ClickStream instance API object. This allows you to create one instance only.
    /// - Parameters:
    ///   - networkConfiguration: Network Configurations needed for connecting socket
    ///   - constraints: ClickStream constraints passed from the integrating app.
    ///   - eventClassification: ClickStream event classification passed from the integrating app.
    /// - Returns: returns a ClickStream instance to keep throughout the project.
    ///            You can always get the instance by calling getInstance()
    @discardableResult public static func initialise(networkConfiguration: NetworkConfigurations,
                                                     constraints: ClickStreamConstraints? = nil,
                                                     eventClassification: ClickStreamEventClassification? = nil) throws -> ClickStream? {
        
        let semaphore = DispatchSemaphore(value: 1)
        defer {
            semaphore.signal()
        }
        semaphore.wait()
        
        guard sharedInstance != nil else {
            
            // Setting Constraints to be used for the SDK.
            if let constraints = constraints {
                ClickStream.constraints = constraints
            } else {
                print("Initialising ClickStream using default constraints.",.verbose)
            }
            
            // Setting Event Classification to be used for the SDK.
            if let eventClassifier = eventClassification {
                ClickStream.eventClassifier = eventClassifier
            } else {
                print("Initialising ClickStream using default event classification",.verbose)
            }
            
            // All the dependency injections pertaining to the clickstream blocks happen here!
            // Load default dependencies.
            do {
                let dependencies = try DefaultClickStreamDependencies(with: networkConfiguration)
                sharedInstance = ClickStream(networkBuilder: dependencies.networkBuilder,
                                             eventWarehouser: dependencies.eventWarehouser,
                                             eventProcessor: dependencies.eventProcessor)
            } catch {
                print("Cannot initialise ClickStream. Dependencies could not be initialised.",.critical)
                // Relay the database error.
                throw ClickStream.ClickStreamError.initialisation(error.localizedDescription)
            }
            
            return sharedInstance
        }
        return sharedInstance
    }
}
