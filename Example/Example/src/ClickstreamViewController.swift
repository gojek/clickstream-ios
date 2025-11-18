//
//  ClickstreamViewController.swift
//  Example
//
//  Created by Abhijeet Mallick on 31/03/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import UIKit
import SwiftProtobuf
import Clickstream
import CourierMQTT

class ClickstreamViewController: UIViewController {

    @IBOutlet private weak var textFieldName: UITextField!
    @IBOutlet private weak var textFieldAge: UITextField!
    @IBOutlet private weak var textFieldGender: UITextField!
    @IBOutlet private weak var textFieldPhoneNumber: UITextField!
    @IBOutlet private weak var textFieldEmail: UITextField!
    @IBOutlet private weak var segementedTab: UISegmentedControl!
    @IBOutlet private weak var configBarButtonItem: UIBarButtonItem!

    private var analyticsManager: AnalyticsManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configBarButtonItem.isEnabled = false
        analyticsManager = AnalyticsManager()
    }
    
    @IBAction func connectClickstream(_ sender: UIButton) {
        if segementedTab.selectedSegmentIndex == 0 {
            // Websocket
            analyticsManager.initialiseClickstream(networkOptions: .init(isWebsocketEnabled: true))
        } else {
            // Courier
            guard let networkOptions = analyticsManager.networkOptions,
                let userCredentials = analyticsManager.courierUserCredentials else {
                presentAlert(title: "Unable to Connect to Courier", message: "Please setup Courier Configurations first")
                return
            }

            analyticsManager.initialiseClickstream(networkOptions: networkOptions)
            analyticsManager.provideUserCredentials(with: userCredentials)
        }
    }
    
    @IBAction func disconnectClickstream(_ sender: UIButton) {
        self.analyticsManager.disconnect()
    }

    @IBAction func sendEventToClickstream(_ sender: UIButton) {
        guard !textFieldAge.text!.isEmpty, !textFieldGender.text!.isEmpty, !textFieldPhoneNumber.text!.isEmpty, !textFieldEmail.text!.isEmpty else {
            presentAlert(title: "Invalid Input", message: "Please fill all the required fields")
            return
        }

        let eventGuid = UUID().uuidString
        self.analyticsManager.trackEvent(guid: eventGuid, message: self.createUser(eventGuid: eventGuid))
    }
    
    @IBAction func sendMultipleEventsToClickstream(_ sender: UIButton) {
        DispatchQueue.concurrentPerform(iterations: Constants.clickCount) { index in
            let eventGuid = UUID().uuidString
            self.analyticsManager.trackEvent(guid: eventGuid, message: self.createUser(eventGuid: eventGuid))
        }
    }
    
    @IBAction func openEventVisualizer(_ sender: Any) {
        self.analyticsManager.openEventVisualizer(onController: self)
    }
    
    @IBAction func switchNetworkSourceTarget(_ sender: UISegmentedControl) {
        navigationItem.rightBarButtonItem?.isEnabled = sender.selectedSegmentIndex == 1
    }
    
    @IBAction func didTapConfigButton(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navigation = storyboard.instantiateViewController(withIdentifier: "CourierConfigViewController") as? UINavigationController, let configView = navigation.viewControllers.first as? CourierConfigViewController else {
            fatalError("MyViewController not found in Main.storyboard")
        }

        configView.didSaveConfig = { [weak self] (config, userCredentials, topic) in
            let whitelistedEvents = ["User"]
            var defaultNetworkOptions = ClickstreamNetworkOptions(isWebsocketEnabled: false,
                                                                  isCourierEnabled: true,
                                                                  courierEventTypes: Set(whitelistedEvents))

            defaultNetworkOptions.courierConfig = config
            self?.analyticsManager.networkOptions = defaultNetworkOptions
            self?.analyticsManager.courierUserCredentials = userCredentials
            self?.analyticsManager.courierTopic = topic
        }

        present(navigation, animated: true)
    }

    @IBAction func autofillEventForm(_ sender: UIBarButtonItem) {
        let names = ["Alice", "Bob", "Charlie", "David", "Emma"]
        let ages = ["20", "30", "40", "50", "60"]
        let genders = ["Female", "Male"]
        let phone = ["1234567890", "2345678901", "3456789012", "4567890123", "5678901234"]
        let email = ["alice@example.com", "bob@example.com", "charlie@example.com", "david@example.com", "emma@example.com"]

        self.textFieldName.text = names.randomElement()
        self.textFieldAge.text = ages.randomElement()
        self.textFieldGender.text = genders.randomElement()
        self.textFieldPhoneNumber.text = phone.randomElement()
        self.textFieldEmail.text = email.randomElement()
    }

    /// Create User from field values
    /// - Returns: User
    private func createUser(eventGuid: String) -> User {
        let user = User.with {
            $0.guid = eventGuid
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

extension UIViewController {
    func presentAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
}
