//
//  ClickstreamViewController.swift
//  Example
//
//  Created by Abhijeet Mallick on 31/03/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import UIKit
import SwiftProtobuf

class ClickstreamViewController: UIViewController {

    @IBOutlet private weak var textFieldName: UITextField!
    @IBOutlet private weak var textFieldAge: UITextField!
    @IBOutlet private weak var textFieldGender: UITextField!
    @IBOutlet private weak var textFieldPhoneNumber: UITextField!
    @IBOutlet private weak var textFieldEmail: UITextField!
    
    private var analyticsManager: AnalyticsManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsManager = AnalyticsManager()
    }
    
    @IBAction func connectClickstream(_ sender: UIButton) {
        analyticsManager.initialiseClickstream()
    }
    
    @IBAction func disconnectClickstream(_ sender: UIButton) {
        self.analyticsManager.disconnect()
    }
    
    @IBAction func sendEventToClickstream(_ sender: UIButton) {
        self.analyticsManager.trackEvent(message: self.createUser())
    }
    
    @IBAction func sendMultipleEventsToClickstream(_ sender: UIButton) {
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            self.analyticsManager.trackEvent(message: self.createUser())
        }
    }
    
    /// Create User from field values
    /// - Returns: User
    private func createUser() -> User {
        let user = User.with {
            $0.guid = Int32.random(in: 0..<1000)
            $0.name = self.textFieldName.text ?? ""
            $0.age = Int32("\(String(describing: self.textFieldAge.text))") ?? 0
            $0.gender = self.textFieldGender.text ?? ""
            $0.phoneNumber = Int64("\(String(describing: self.textFieldPhoneNumber.text))") ?? 0
            $0.email = self.textFieldEmail.text ?? ""
            
            $0.app = App.with {
                $0.version = "1.0.0"
                $0.packageName = "com.clickstream.app"
            }
            
            $0.device = Device.with {
                $0.operatingSystem = "iOS"
                $0.operatingSystemVersion = UIDevice.current.systemVersion
                $0.deviceMake = "Apple"
                $0.deviceModel = "iPhone 13 Pro"
            }
            
            $0.deviceTimestamp = Google_Protobuf_Timestamp(date: Date())
        }
        
        return user
    }
}
