//
//  Array+Extension.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 02/05/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import Foundation

extension Array {
    public func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
