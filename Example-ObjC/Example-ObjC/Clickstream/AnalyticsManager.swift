//
//  AnalyticsManager.swift
//  Example-ObjC
//
//  Created by Abhijeet Mallick on 14/02/24.
//

import Foundation
import Clickstream
import Protobuf

@objcMembers
public class AnalyticsManager: NSObject {
    
    private var clickstream: Clickstream?
    
    /// Initialise Clickstream
    @objc public func initialiseClickstream() {
        
        Clickstream.setLogLevel(.verbose)
        do {
            let header = createHeader()
            let request = self.urlRequest(headerParamaters: header)
            
            let configurations = ClickstreamConstraints(maxConnectionRetries: 5)
            let classification = ClickstreamEventClassification()

            self.clickstream = try Clickstream.initialise(
                with: request ?? URLRequest(url: URL(string: "")!),
                configurations: configurations,
                eventClassification: classification,
                appPrefix: ""
            )
        } catch  {
            print(error.localizedDescription)
        }
    }

    /// Track events using Clickstream
    /// - Parameter message: Proto that needs to be tracked
    @objc func trackEvent(guid: String, message: GPBMessage) {
        guard let clickstream = clickstream else {
            assertionFailure("Need to initialise clicksteam first before trying to send events!")
            return
        }
        guard let serializedData = message.data() else {
            print("message.data() is empty")
            return
        }
        let eventDTO = ClickstreamEvent(guid: guid, timeStamp: Date(), message: nil, eventName: type(of: message).description(), eventData: serializedData)
        clickstream.trackEvent(with: eventDTO)
    }
    
    /// De-initialize Clickstream
    @objc func disconnect() {
        Clickstream.destroy()
        clickstream = nil
    }
}

extension AnalyticsManager: TrackerDataSource {
    public func currentUserLocation() -> CSLocation? {
        return CSLocation(longitude: 0.0, latitude: 0.0)
    }
    
    @objc public func currentNTPTimestamp() -> Date? {
        return Date()
    }
}

extension AnalyticsManager: TrackerDelegate {
    public func getHealthEvent(event: HealthTrackerDTO) {
        print("\(event.eventName ?? ""): \(event)")
    }
}

extension AnalyticsManager {
    private func url() -> URL? {
        return URL(string: "enter-your-url-here.com")
    }
    
    private func urlRequest(headerParamaters: [String: String]) -> URLRequest? {
        
        guard let url = self.url() else { return nil }
        var urlRequest = URLRequest(url: url)
        let allHeaders: [String: String] = headerParamaters

        urlRequest.allHTTPHeaderFields = allHeaders
        return urlRequest
    }
    
    private func createHeader() -> [String: String] {
        let integrationApiKey = "" // Add API key here
        if let credentialsData = integrationApiKey.data(using: String.Encoding.utf8) {
            let base64CredentialsString = credentialsData.base64EncodedString()
        
            return ["Authorization": "Basic \(base64CredentialsString)",
                "X-UniqueId": "\(UIDevice.current.identifierForVendor?.uuidString ?? "")"]
        } else {
            return [:]
        }
    }
}
