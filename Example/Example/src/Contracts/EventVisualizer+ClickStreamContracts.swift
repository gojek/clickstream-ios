//
//  EventVisualizer+ClickStreamContracts.swift
//  Example
//
//  Created by Abhijeet Mallick on 08/01/24.
//  Copyright © 2024 Gojek. All rights reserved.
//

import Foundation
import SwiftProtobuf

#if EVENT_VISUALIZER_ENABLED
import Clickstream

extension User: CollectionMapper { }
extension Device: CollectionMapper { }
extension App: CollectionMapper { }
extension SwiftProtobuf.Google_Protobuf_Timestamp: CollectionMapper { }
#endif
