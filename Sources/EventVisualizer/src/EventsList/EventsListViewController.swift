//
//  EventsListViewController.swift
//  Launchpad
//
//  Created by Rishav Gupta on 11/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

#if EVENT_VISUALIZER_ENABLED
import SwiftProtobuf
import UIKit

final class EventsListViewController: UIViewController {

    private let tableView: UITableView = UITableView()
    
    private let viewModel: EventsListViewModel = EventsListViewModel()
    var selectedEventName: String?
    var eventDict: [Message]?
    
    // MARK: - View Life Cycle
    override func loadView() {
        view = UIView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.viewDidLoad(messages: eventDict, selectedEventName: selectedEventName)
        setUpViews()
        setUpLayout()
    }
    
    private func setUpViews() {
        setTitle()

        view.backgroundColor = .white
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.register(EventsListingTableViewCell.self)
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
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        tableView.translatesAutoresizingMaskIntoConstraints = false
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
#endif
