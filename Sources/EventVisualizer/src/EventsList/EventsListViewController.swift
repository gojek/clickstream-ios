//
//  EventsListViewController.swift
//  EventVisualizer
//
//  Created by Rishav Gupta on 11/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import SwiftProtobuf
import UIKit

final class EventsListViewController: UIViewController {

    private let tableView: UITableView = UITableView()
    private let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
    private let loadingProgressLabel: UILabel = UILabel()
    private let loadingStackView: UIStackView = UIStackView()

    private let viewModel: EventsListViewModel = EventsListViewModel()
    var selectedEventName: String?
    var eventDict: [Message]?

    // MARK: - View Life Cycle
    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViews()
        setUpLayout()
        showLoadingState()
        loadEvents()
    }

    private func setUpViews() {
        setTitle()

        view.backgroundColor = .white

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.register(EventsListingTableViewCell.self)
        tableView.isHidden = true

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .gray
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        loadingProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingProgressLabel.textAlignment = .center
        loadingProgressLabel.numberOfLines = 0
        loadingProgressLabel.textColor = .secondaryLabel
        loadingProgressLabel.font = .systemFont(ofSize: 14.0, weight: .regular)
        loadingProgressLabel.text = "Processing 0 / 0 messages"

        loadingStackView.axis = .vertical
        loadingStackView.alignment = .center
        loadingStackView.spacing = 10.0
        loadingStackView.translatesAutoresizingMaskIntoConstraints = false
        loadingStackView.addArrangedSubview(loadingIndicator)
        loadingStackView.addArrangedSubview(loadingProgressLabel)
    }

    private func setTitle() {
        if #available(iOS 13.0, *) {
            let navView = UIView()

            // Create the label
            let label = UILabel()
            label.text = "Events List"
            label.sizeToFit()
            label.center = navView.center
            label.textAlignment = NSTextAlignment.center
            /// Create the image view
            let image = UIImageView()
            image.image = UIImage(systemName: "wrench.and.screwdriver")
            /// To maintain the image's aspect ratio:
            if let actualImage = image.image {
            let imageAspect = actualImage.size.width / actualImage.size.height
                /// Setting the image frame so that it's immediately before the text:
                image.frame = CGRect(x: label.frame.origin.x - label.frame.size.height * imageAspect, y: label.frame.origin.y, width: label.frame.size.height * imageAspect, height: label.frame.size.height)
                image.contentMode = UIView.ContentMode.scaleAspectFit
            }
            let statusView = EventsHelper.shared.getCSConnectionStateView(title: label)
            /// Add both the label and image view to the navView
            navView.addSubview(label)
            navView.addSubview(image)
            navView.addSubview(statusView.statusImage)
            navView.addSubview(statusView.statusLabel)

            self.navigationItem.titleView = navView
            navView.sizeToFit()
        } else {
            title = "Events List"
        }
    }

    private func setUpLayout() {
        view.addSubview(tableView)
        view.addSubview(loadingStackView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24.0),
            loadingStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24.0)
        ])
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func showLoadingState() {
        tableView.isHidden = true
        loadingStackView.isHidden = false
        loadingIndicator.startAnimating()
    }

    private func hideLoadingState() {
        loadingIndicator.stopAnimating()
        loadingStackView.isHidden = true
        tableView.isHidden = false
    }

    private func loadEvents() {
        viewModel.viewDidLoad(messages: eventDict, selectedEventName: selectedEventName, progress: { [weak self] processedCount, totalCount in
            guard let self = self else { return }
            self.loadingProgressLabel.text = "Processed \(processedCount) / \(totalCount) messages"
        }, completion: { [weak self] in
            guard let self = self else { return }
            self.hideLoadingState()
            self.tableView.reloadData()
        })
    }
}
// MARK: - UITableViewDelegate

extension EventsListViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showEventDetails(viewModel.didSelectRow(at: indexPath))
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
}

// MARK: - UITableViewDataSource

extension EventsListViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.cellsCount
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell() as EventsListingTableViewCell
        cell.apply(viewModel.cellViewModel(for: indexPath))
        return cell
    }

    func showEventDetails(_ message: Message?) {
        let viewController = EventDetailsViewController()
        viewController.messageSelected = message
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)

    }
}
