//
//  CourierConfigViewController.swift
//  Example
//
//  Created by Luqman Fauzi on 16/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import UIKit
import Clickstream

final class CourierConfigViewController: UITableViewController {

    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var deviceIdTextField: UITextField!
    @IBOutlet weak var bundleIdTextField: UITextField!
    @IBOutlet weak var extrraIdTextField: UITextField!

    @IBOutlet weak var baseUrlTextField: UITextField!
    @IBOutlet weak var urlPathTextField: UITextField!

    @IBOutlet weak var adapterProtobufEnabled: UISwitch!
    @IBOutlet weak var adapterJSONEnabled: UISwitch!
    @IBOutlet weak var adapterDataEnabled: UISwitch!
    @IBOutlet weak var adapterTextEnabled: UISwitch!
    @IBOutlet weak var adapterPlistEnabled: UISwitch!

    @IBOutlet weak var topicTextField: UITextField!
    @IBOutlet weak var topicQoSTab: UISegmentedControl!

    @IBOutlet weak var connectPolicyEnabledSwitch: UISwitch!
    @IBOutlet weak var connectPolicyTimerIntervalTextField: UITextField!
    @IBOutlet weak var connectPolicyTimeoutTextField: UITextField!

    @IBOutlet weak var iddlePolicyEnabledSwitch: UISwitch!
    @IBOutlet weak var iddlePolicyTimerIntervalTextField: UITextField!
    @IBOutlet weak var iddlePolicyTimeoutTextField: UITextField!
    @IBOutlet weak var iddlePolicyReadTimeoutTextField: UITextField!

    var config: ClickstreamCourierConfig?
    var userCredentials: ClickstreamCourierUserCredentials?

    var didSaveConfig: ((_ config: ClickstreamCourierConfig, _ userCredentials: ClickstreamCourierUserCredentials) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupConfigs()
    }

    private func setupConfigs() {
        userIdTextField.text = userCredentials?.userIdentifier.description
        deviceIdTextField.text = userCredentials?.deviceIdentifier.description
        bundleIdTextField.text = userCredentials?.bundleIdentifier?.description
        extrraIdTextField.text = userCredentials?.extraIdentifier?.description
        
        baseUrlTextField.text = config?.connectConfig.baseURL
        urlPathTextField.text = config?.connectConfig.authURLPath

        adapterProtobufEnabled.isOn = config?.messageAdapters.contains(.protobuf) ?? false
        adapterJSONEnabled.isOn = config?.messageAdapters.contains(.json) ?? false
        adapterDataEnabled.isOn = config?.messageAdapters.contains(.data) ?? false
        adapterTextEnabled.isOn = config?.messageAdapters.contains(.text) ?? false
        adapterPlistEnabled.isOn = config?.messageAdapters.contains(.plist) ?? false

        topicTextField.text = config?.topics.first?.key
        topicQoSTab.selectedSegmentIndex = config?.topics.first?.value ?? 0
        
        connectPolicyEnabledSwitch.isOn = config?.connectTimeoutPolicy.isEnabled ?? false
        connectPolicyTimerIntervalTextField.text = config?.connectTimeoutPolicy.timerInterval.description
        connectPolicyTimeoutTextField.text = config?.connectTimeoutPolicy.timeout.description

        iddlePolicyEnabledSwitch.isOn = config?.iddleActivityPolicy.isEnabled ?? false
        iddlePolicyTimerIntervalTextField.text = config?.iddleActivityPolicy.timerInterval.description
        iddlePolicyTimeoutTextField.text = config?.iddleActivityPolicy.timerInterval.description
        iddlePolicyReadTimeoutTextField.text = config?.iddleActivityPolicy.readTimeout.description
    }

    @IBAction func onTapSaveButton(_ sender: UIBarButtonItem) {
        guard let config, let userCredentials else {
            presentAlert(title: "Missing Config", message: "Please fill in required config")
            return
        }

        presentAlert(title: "Config Updated", message: "Courier config has been saved") { [weak self] in
            self?.dismiss(animated: true)
        }
        didSaveConfig?(config, userCredentials)
    }

    @IBAction func onTapCancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}

