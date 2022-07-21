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
    private var ntpClient: DefaultNTPClient?
    
    /// Initialise Clickstream
    func initialiseClickstream() {
        
        do {
            Clickstream.setLogLevel(.verbose)
            let url = URL(string: "ws://mock.clickstream.com/events")!
            
            let constraints = ClickstreamConstraints(maxConnectionRetries: 5)
            let classification = ClickstreamEventClassification()
            
            self.clickstream = try Clickstream.initialise(request: URLRequest(url: url),
                                                          constraints: constraints,
                                                          eventClassification: classification,
                                                          dataSource: self,
                                                          delegate: self)
            
            self.setClickstreamTracker()
            #if EVENT_VISUALIZER_ENABLED
            EventsHelper.shared.startCapturing()
            #endif
        } catch  {
            print(error.localizedDescription)
        }
        self.ntpClient = DefaultNTPClient.initialise(isNtpEnabled: true, ntpHost: "time.google.com")
    }
    
    /// Set Clickstream Health Tracker
    private func setClickstreamTracker() {
        
        let customerInfo = CSCustomerInfo(signedUpCountry: "India", email: "test@test.com", currentCountry: "91", identity: 105)
        let sessionInfo = CSSessionInfo(sessionId: "1001")
        let appInfo = CSAppInfo(version: "1.1.0")
        let commonProperties = CSCommonProperties(customer: customerInfo, session: sessionInfo, app: appInfo)
        let configs = ClickstreamHealthConfigurations(minimumTrackedVersion: "0.1", trackedVia: .internal)
        
        self.clickstream?.setTracker(configs: configs, commonProperties: commonProperties, dataSource: self, delegate: self)
    }
    
    /// Track events using Clickstream
    /// - Parameter message: Proto that needs to be tracked
    func trackEvent(guid: String, message: Message) {
        guard let clickstream = clickstream else {
            assertionFailure("Need to initialise clicksteam first before trying to send events!")
            return
        }

        let eventDTO = ClickstreamEvent(guid: guid,
                                        timeStamp: Date(),
                                        message: message)
        clickstream.trackEvent(with: eventDTO)
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

extension AnalyticsManager: ClickstreamDataSource {
    func currentNTPTimestamp() -> Date? {
        return self.ntpClient?.now()
    }
}

extension AnalyticsManager: ClickstreamDelegate {
    func onConnectionStateChanged(state: Clickstream.ConnectionState) {
        switch state {
        case.connecting:
            print("Socket is trying to connect")
        case .connected:
            print("Socket connection gets connected")
        case .closing:
            print("Socket is about to be closed, can be called when the app moves to backgroud")
        case .closed:
            print("Socket connection is closed")
        case .failed:
            print("Socket connection is fails")
        }
    }
}

extension AnalyticsManager: TrackerDataSource {
    func currentUserLocation() -> CSLocation? {
        return CSLocation(longitude: 0.0, latitude: 0.0)
    }
}

extension AnalyticsManager: TrackerDelegate {
    func getHealthEvent(event: HealthTrackerDTO) {
        print("\(event.eventName): \(event)")
    }
}
