//
//  AnalyticsManager.swift
//  Example
//
//  Created by Abhijeet Mallick on 19/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import Clickstream
import SwiftProtobuf

class AnalyticsManager {
    
    private var clickstream: Clickstream?
    
    /// Initialise Clickstream
    func initialiseClickstream() {
        
        Clickstream.setLogLevel(.verbose)
        do {
            let header = createHeader()
            let request = self.urlRequest(headerParamaters: header)
            
            let configurations = ClickstreamConstraints(maxConnectionRetries: 5)
            let classification = ClickstreamEventClassification()
            let healthConfig = ClickstreamHealthConfigurations()

            self.clickstream = try Clickstream.initialise(
                with: request ?? URLRequest(url: URL(string: "")!),
                configurations: configurations,
                eventClassification: classification,
                healthTrackingConfigs: healthConfig,
                dataSource: self,
                appPrefix: ""
            )
        } catch  {
            print(error.localizedDescription)
        }
        
        #if EVENT_VISUALIZER_ENABLED
        EventsHelper.shared.startCapturing()
        #endif
    }

    /// Track events using Clickstream
    /// - Parameter message: Proto that needs to be tracked
    func trackEvent(guid: String, message: Message) {
        guard let clickstream = clickstream else {
            assertionFailure("Need to initialise clicksteam first before trying to send events!")
            return
        }
        
        do {
            let eventDTO = ClickstreamEvent(
                guid: guid,
                timeStamp: Date(),
                message: message,
                eventName: type(of: message).protoMessageName,
                eventData: try message.serializedData())
            clickstream.trackEvent(with: eventDTO)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// De-initialize Clickstream
    func disconnect() {
        Clickstream.destroy()
        clickstream = nil
    }
    
    #if EVENT_VISUALIZER_ENABLED
    func openEventVisualizer(onController: UIViewController) {
        let viewController = EventVisualizerLandingViewController()
        viewController.hidesBottomBarWhenPushed = true
        let navVC = UINavigationController(rootViewController: viewController)
        navVC.modalPresentationStyle = .overCurrentContext
        navVC.navigationBar.barTintColor = UIColor.white
        navVC.navigationBar.tintColor = UIColor.black
        onController.present(navVC, animated: true, completion: nil)
    }
    #endif
}

extension AnalyticsManager: TrackerDataSource {
    func currentUserLocation() -> CSLocation? {
        return CSLocation(longitude: 0.0, latitude: 0.0)
    }
}

extension AnalyticsManager: TrackerDelegate {
    func getHealthEvent(event: HealthTrackerDTO) {
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

extension AnalyticsManager: ClickstreamDataSource {
    func currentNTPTimestamp() -> Date? {
        return Date()
    }
}
