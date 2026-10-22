//
//  CSLocation.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
@_spi(ClickstreamInternal) import Clickstream
#endif
import SwiftProtobuf

/**
 Coordinates of the device, where the event has been generated.
 - important: This must be set using the `ClickstreamDataSource` only.
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

extension CSLocation: TrackerProtoConvertible {
    var proto: Gojek_Clickstream_Internal_HealthMeta.Location {
        let location = Gojek_Clickstream_Internal_HealthMeta.Location.with {
            $0.latitude = self.latitude
            $0.longitude = self.longitude
        }
        return location
    }
}
