//
//  AppStateNotifierMock.swift
//  ClickStreamTests
//
//  Created by Anirudh Vyas on 05/06/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

final class AppStateNotifierMock: AppStateNotifierService {
    
    private let state: AppStateNotificationType
    
    init(state: AppStateNotificationType) {
        self.state = state
    }
        
    func start(with subscriber: @escaping (AppStateNotificationType) -> ()) {
        subscriber(state)
    }
    
    func stop() {
        
    }
}
