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
        } catch  {
            print(error.localizedDescription)
        }
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
