//
//  CSLocation.swift
//  ClickStream
//
//  Created by Anirudh Vyas on 21/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

/**
 Coordinates of the device, where the event has been generated.
 - important: This must be set using the `ClickStreamDataSource` only.
 */
public struct CSLocation {
    
    /// Holds the longitudinal value.
    var longitude: Double
    /// Holds the latitudinal value.
    var latitude: Double
    
    /// Public initialiser for `CSLocation`
    /// - Parameters:
    ///   - longitude: longitudinal value.
    ///   - latitude: latitudinal value.
    public init(longitude: Double, latitude: Double) {
        self.longitude = longitude
        self.latitude = latitude
    }
}
