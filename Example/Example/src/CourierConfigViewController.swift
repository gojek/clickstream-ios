//
//  CourierConfigViewController.swift
//  Example
//
//  Created by Luqman Fauzi on 16/10/25.
//  Copyright © 2025 Gojek. All rights reserved.
//

import UIKit
import Clickstream
import CourierMQTT

final class CourierConfigViewController: UITableViewController {

    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var deviceIdTextField: UITextField!
    @IBOutlet weak var bundleIdTextField: UITextField!
    @IBOutlet weak var extrraIdTextField: UITextField!

    @IBOutlet weak var urlHostTextField: UITextField!
    @IBOutlet weak var urlPathTextField: UITextField!
    @IBOutlet weak var urlQueriesTextField: UITextField!

    @IBOutlet weak var adapterJSONEnabled: UISwitch!
    @IBOutlet weak var adapterDataEnabled: UISwitch!
    @IBOutlet weak var adapterTextEnabled: UISwitch!
    @IBOutlet weak var adapterPlistEnabled: UISwitch!

    @IBOutlet weak var topicTextField: UITextField!

    @IBOutlet weak var connectPolicyEnabledSwitch: UISwitch!
    @IBOutlet weak var connectPolicyTimerIntervalTextField: UITextField!
    @IBOutlet weak var connectPolicyTimeoutTextField: UITextField!

    @IBOutlet weak var iddlePolicyEnabledSwitch: UISwitch!
    @IBOutlet weak var iddlePolicyTimerIntervalTextField: UITextField!
    @IBOutlet weak var iddlePolicyTimeoutTextField: UITextField!
    @IBOutlet weak var iddlePolicyReadTimeoutTextField: UITextField!

    private var config: ClickstreamCourierConfig?
    private var userCredentials: ClickstreamClientIdentifiers?

    var didSaveConfig: ((_ config: ClickstreamCourierConfig, _ userCredentials: ClickstreamClientIdentifiers, _ topic: String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupConfigs()
    }

    private func setupConfigs() {
        // ================
        // Must be provided
        let userIdentifier = ""
        let host = urlHostTextField.text
        let path = urlPathTextField.text
        let queries = urlQueriesTextField.text
        let headers: [String: String] = [:]
        let topic = topicTextField.text
        // ================

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host
        urlComponents.path = path ?? ""
        urlComponents.queryItems = queries?.split(separator: "&").compactMap {
            URLQueryItem(name: String($0.split(separator: "=")[0]), value: String($0.split(separator: "=")[1]))
        }

        guard let url = urlComponents.url else {
            assertionFailure("Auth URL must be valid")
            return
        }

        var urlRequest = URLRequest(url: url)
        headers.forEach {
            urlRequest.setValue($0.value, forHTTPHeaderField: $0.key)
        }

        userCredentials = CourierIdentifiers(
            userIdentifier: userIdentifier,
            authURLRequest: urlRequest
        )

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)

        let messageAdapter = EnvelopeMessageAdapter(messageAdapters: [JSONMessageAdapter(jsonDecoder: decoder), DataMessageAdapter()],
                                                    isToMessageEnabled: false)

        config = ClickstreamCourierConfig(messageAdapter: [messageAdapter])

        userIdTextField.text = userCredentials?.userIdentifier.description
        deviceIdTextField.text = userCredentials?.deviceIdentifier.description
        bundleIdTextField.text = userCredentials?.bundleIdentifier?.description
        extrraIdTextField.text = userCredentials?.extraIdentifier?.description
        urlHostTextField.text = host
        urlPathTextField.text = path
        urlQueriesTextField.text = queries
        topicTextField.text = topic

        guard let config else { return }
        for adapter in config.messageAdapters {
            switch adapter {
            case is JSONMessageAdapter:
                adapterJSONEnabled.isOn = true
            case is DataMessageAdapter:
                adapterDataEnabled.isOn = true
            case is PlistMessageAdapter:
                adapterPlistEnabled.isOn = true
            case is TextMessageAdapter:
                adapterTextEnabled.isOn = true
            default:
                break
            }
        }
        
        connectPolicyEnabledSwitch.isOn = config.connectTimeoutPolicy.isEnabled
        connectPolicyTimerIntervalTextField.text = config.connectTimeoutPolicy.timerInterval.description
        connectPolicyTimeoutTextField.text = config.connectTimeoutPolicy.timeout.description
        
        iddlePolicyEnabledSwitch.isOn = config.iddleActivityPolicy.isEnabled
        iddlePolicyTimerIntervalTextField.text = config.iddleActivityPolicy.timerInterval.description
        iddlePolicyTimeoutTextField.text = config.iddleActivityPolicy.timerInterval.description
        iddlePolicyReadTimeoutTextField.text = config.iddleActivityPolicy.readTimeout.description
    }

    @IBAction func onTapSaveButton(_ sender: UIBarButtonItem) {
        guard let config, let userCredentials, let topic = self.topicTextField.text, !topic.isEmpty else {
            presentAlert(title: "Missing Config", message: "Please fill in required config")
            return
        }

        presentAlert(title: "Config Updated", message: "Courier config has been saved") { [weak self] in
            self?.dismiss(animated: true)
        }

        didSaveConfig?(config, userCredentials, topic)
    }

    @IBAction func onTapCancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}

