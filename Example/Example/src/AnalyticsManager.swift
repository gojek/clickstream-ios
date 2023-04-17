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
            let authToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJhdWQiOlsiZ29qZWsiLCJtaWR0cmFucyIsImdvdmlldCIsImdvcGF5IiwiZ29wbGF5Il0sImRhdCI6eyJhY3RpdmUiOiJ0cnVlIiwiYmxhY2tsaXN0ZWQiOiJmYWxzZSIsImNvdW50cnlfY29kZSI6Iis5MSIsImNyZWF0ZWRfYXQiOiIyMDIyLTAyLTIzVDE1OjE1OjAwWiIsImVtYWlsIjoicmlzaGF2Lmd1cHRhQGdvamVrLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjoiZmFsc2UiLCJnb3BheV9hY2NvdW50X2lkIjoiMDEtYjg4NzA0MjFkMGI5NDhmYWJiODkyZDc2NjU0MWY4NWQtMjciLCJuYW1lIjoiUmlzaGF2IEd1cHRhIiwibnVtYmVyIjoiODk2MTY4MjE3MiIsInBob25lIjoiKzkxODk2MTY4MjE3MiIsInNpZ25lZF91cF9jb3VudHJ5IjoiSUQiLCJ3YWxsZXRfaWQiOiIyMjA1NDA5MTc1NzAxNjk3MjEifSwiZXhwIjoxNjU5MDY5OTQ1LCJpYXQiOjE2NTYzMDkxMDYsImlzcyI6ImdvaWQiLCJqdGkiOiI4MGFjNTg1MS0yZjI0LTQ0YTQtYWYzOS0zMGZkMjM3Y2YyMmUiLCJzY29wZXMiOltdLCJzaWQiOiJhZGVhOTQyZS04ZmY1LTQ4NzctYWZjNi1mNjk5OWI5M2MwZWUiLCJzdWIiOiJjNDNjZWM3YS0xNTgzLTRjYjgtOGMzMy00OWE1ZjJjOWMxMmEiLCJ1aWQiOiIyNDAzNDkwIiwidXR5cGUiOiJjdXN0b21lciJ9.XeKzv0RcIA8DgmOhx_O4xoYyrVifsy1MF3MpBPmUsU2MzdZd1mdNV3s76IVlJ63h-J4kra-PjsfGEk0uo5Mjy-R_2_XFKaSa2pNGbPkQAld4AwoAAgxryKJ4lj8Zzy7N0hnM3xSESWpgo9-Um7ci9vXxFL2iZPXF2cbYruyRtFk"
            let header = createHeader(with: authToken)
            let request = self.urlRequest(headerParamaters: header)
            self.clickstream = try Clickstream.initialise(with: request ?? URLRequest(url: URL(string: "")!), configurations: Constants.configurations, eventClassification: Constants.eventClassification, healthTrackingConfigs: Constants.healthTrackingConfigurations, dataSource: self, appPrefix: "")
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
        guard let url = URL(string: "https://raccoon-integration.gojekapi.com") else { return nil }
        let baseURL = url.absoluteString.last != "/" ? url.absoluteString + "/" : url.absoluteString
        let endpoint = baseURL.appending("api/v1/events")
        
        guard let urlComponents = URLComponents(string: endpoint) else { return nil }
        guard let url = urlComponents.url else { return nil }
        return url
    }
    
    private func urlRequest(headerParamaters: [String: String]) -> URLRequest? {
        
        guard let url = self.url() else { return nil }
        var urlRequest = URLRequest(url: url)
        let allHeaders: [String: String] = headerParamaters

        urlRequest.allHTTPHeaderFields = allHeaders
        return urlRequest
    }
    
    private func createHeader(with bearer: String) -> [String: String] {
        let integrationApiKey = "deee48c3-65ed-4a78-b4ad-4647788d49a6"
        if let credentialsData = integrationApiKey.data(using: String.Encoding.utf8) {
            let base64CredentialsString = credentialsData.base64EncodedString()
        
            return ["Authorization": "Basic \(base64CredentialsString)",
                "X-UniqueId": "\(UIDevice.current.identifierForVendor?.uuidString ?? "")"]
        } else {
            return ["Authorization": "Bearer \(bearer)"]
        }
    }
}

extension AnalyticsManager: ClickStreamDataSource {
    func currentNTPTimestamp() -> Date? {
        return Date()
    }
}
