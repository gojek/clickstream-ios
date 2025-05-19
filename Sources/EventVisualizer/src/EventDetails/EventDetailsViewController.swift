//
//  EventDetailsViewController.swift
//  SettingsKit
//
//  Created by Rishav Gupta on 14/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

#if EVENT_VISUALIZER_ENABLED
import SwiftProtobuf
import UIKit

final class EventDetailsViewController: UIViewController {

    private let tableView: UITableView = UITableView()
    private let searchBar: UISearchBar = UISearchBar()
    private var searchBarClearButton: UIButton? {
        return (searchBar.value(forKey: "searchField") as? UITextField)?.value(forKey: "_clearButton") as? UIButton
    }
    
    private let viewModel: EventDetailsViewModel = EventDetailsViewModel()
    var messageSelected: Message?
    
    // MARK: - View Life Cycle
    override func loadView() {
        view = UIView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.viewDidLoad(message: messageSelected)
        setUpViews()
        setUpLayout()
    }
    
    private func setUpViews() {
        setTitle()

        view.backgroundColor = .white
        
        searchBar.delegate = self
        searchBar.placeholder = "Search property..."
        searchBar.frame = CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: 44.0))
        searchBarClearButton?.addTarget(self, action: #selector(searchBarClearButtonDidTap), for: .touchUpInside)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = searchBar
        tableView.keyboardDismissMode = .interactive
        tableView.register(EventsListingTableViewCell.self)
    }
    
    private func setTitle() {
        if #available(iOS 13.0, *) {
            let navView = UIView()

            // Create the label
            let label = UILabel()
            label.text = "Event Details"
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
            title = "Event Detail"
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
    
    @objc private func searchBarClearButtonDidTap(_ clearButton: UIButton) {
        searchBar.endEditing(true)
    }
}

// MARK: - UITableViewDelegate

extension EventDetailsViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
}

// MARK: - UITableViewDataSource

extension EventDetailsViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.cellsCount()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell() as EventsListingTableViewCell
        if viewModel.isSearchActive && viewModel.searchText != "" {
            cell.apply(viewModel.cellViewModel(for: indexPath, with: viewModel.searchedMessage))
        } else {
            cell.apply(viewModel.cellViewModel(for: indexPath, with: viewModel.displayedMessage))
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectRow(at: indexPath)
        showMessage(message: "Copied value to clipboard", font: .boldSystemFont(ofSize: 14.0))
    }
}
extension UIViewController {
    func showMessage(message: String, font: UIFont) {
        
        let bannerText = UILabel(frame: CGRect(x: self.view.frame.size.width / 2 - 100, y: self.view.frame.size.height - 100, width: 200, height: 50))
        bannerText.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        bannerText.textColor = UIColor.white
        bannerText.font = font
        bannerText.textAlignment = .center
        bannerText.text = message
        bannerText.alpha = 2.0
        bannerText.layer.cornerRadius = 5
        bannerText.clipsToBounds = true
        self.view.addSubview(bannerText)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            bannerText.alpha = 0.0
        }, completion: {(_) in
            bannerText.removeFromSuperview()
        })
    }
}
extension EventDetailsViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.endEditing(true)
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
        tableView.reloadData()
    }
    
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        viewModel.isSearchActive = true
        tableView.reloadData()
    }
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        viewModel.isSearchActive = false
        tableView.reloadData()
    }
}
#endif
