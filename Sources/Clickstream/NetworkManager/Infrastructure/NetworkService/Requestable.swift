//
//  Requestable.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 21/04/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

protocol Requestable {
    
    func urlRequest() throws -> URLRequest
}
