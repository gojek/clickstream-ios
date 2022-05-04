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
        do {
            Clickstream.setLogLevel(.verbose)
            let url = URL(string: "ws://mock.clickstream.com/events")!
            let headers = ["Authorization": "Bearer dummy-token"]
            
            let networkConfigs = NetworkConfigurations(baseURL: url, headers: headers)
            
            let constraints = ClickstreamConstraints(maxConnectionRetries: 5)
            let classification = ClickstreamEventClassification()
            
            self.clickstream = try Clickstream.initialise(networkConfiguration: networkConfigs,
                                                          constraints: constraints,
                                                          eventClassification: classification)
            
            let configs = ClickstreamHealthConfigurations(minimumTrackedVersion: "1.0", destination: ["CT", "CS"])
            let commonProperties = CSCommonProperties(customer: self.getCustomerInfo(), session: getSessionInfo(), app: getAppInfo())
            Tracker.initialise(dataSource: self, commonEventProperties: commonProperties, healthTrackingConfigs: configs)
        } catch  {
            print(error.localizedDescription)
        }
    }
    
//    private func setCommomProperties() {
//        let commonProperties = CSCommonProperties(customer: self.getCustomerInfo(), session: getSessionInfo(), app: getAppInfo())
////        self.clickStream?.commonEventProperties = commonProperties
//    }
    
    private func getAppInfo() -> CSAppInfo {
        return CSAppInfo(version: "1.0")
    }
    
    private func getCustomerInfo() -> CSCustomerInfo {
        let customerInfo = CSCustomerInfo(signedUpCountry: "India", email: "test@test.com", currentCountry: "91", identity: 105)
        return customerInfo
    }
    
    private func getSessionInfo() -> CSSessionInfo {
        let sessionInfo = CSSessionInfo(sessionId: "1")
        return sessionInfo
    }
    
    /// Track events using Clickstream
    /// - Parameter message: Proto that needs to be tracked
    func trackEvent(message: Message) {
        guard let clickstream = clickstream else {
            assertionFailure("Need to initialise clicksteam first before trying to send events!")
            return
        }

        let eventDTO = ClickstreamEvent(guid: UUID().uuidString,
                                        timeStamp: Date(),
                                        message: message)
        clickstream.trackEvent(with: eventDTO)
    }
    
    /// De-initialize Clickstream
    func disconnect() {
        Clickstream.destroy()
        clickstream = nil
    }
}

extension AnalyticsManager: ClickstreamHealthDataSource {
    func currentUserLocation() -> CSLocation? {
        return CSLocation(longitude: 0.0, latitude: 0.0)
    }
    
    
}

