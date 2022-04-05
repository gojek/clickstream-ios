//
//  EventSpecificData.swift
//  ClickStream
//
//  Created by Abhijeet Mallick on 03/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

struct EventSpecificData {
    var uuid: String
    var timeStamp: Date
    
    init() {
        self.uuid = UUID().uuidString
        self.timeStamp = Date()
    }
}
