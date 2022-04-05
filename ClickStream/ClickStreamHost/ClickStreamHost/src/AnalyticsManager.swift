//
//  AnalyticsManager.swift
//  ClickStreamHost
//
//  Created by Abhijeet Mallick on 19/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import ClickStream
import SwiftProtobuf

class AnalyticsManager {
    
    private var clickstream: ClickStream?
    
    /// Initialise Clickstream
    func initialiseClickstream() {
        do {
            ClickStream.setLogLevel(.verbose)
            let url = URL(string: "ws://mock.clickstream.com/events")!
            let headers = ["Authorization": "Bearer dummy-token"]
            
            let networkConfigs = NetworkConfigurations(baseURL: url, headers: headers)
            
            let constraints = ClickStreamConstraints(maxConnectionRetries: 5)
            let classification = ClickStreamEventClassification()
            
            self.clickstream = try ClickStream.initialise(networkConfiguration: networkConfigs,
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
        ClickStream.destroy()
        clickstream = nil
    }
}
