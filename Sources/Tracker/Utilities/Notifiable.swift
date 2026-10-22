//
//  Notifiable.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 26/08/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
@_spi(ClickstreamInternal) import Clickstream
#endif

protocol Notifiable {
    func notify()
}
