//
//  EventVisualizerLandingViewController.swift
//  Launchpad
//
//  Created by Rishav Gupta on 07/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import SwiftProtobuf
import UIKit

final public class EventVisualizerLandingViewController: UIViewController {

    private let tableView: UITableView = UITableView()
    private let searchBar: UISearchBar = UISearchBar()
    private var searchBarClearButton: UIButton? {
        return (searchBar.value(forKey: "searchField") as? UITextField)?.value(forKey: "_clearButton") as? UIButton
    }
    
    private var alertController = UIAlertController()
    private var filterTableView = UITableView()
    
    var filterSelected: [String] = []
    
    private let viewModel: EventVisualizerLandingViewModelInput = EventVisualizerLandingViewModel()
    
    // MARK: - View Life Cycle
    public override func loadView() {
        view = UIView()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad()
        setUpViews()
        setUpLayout()
    }
    
    private func setUpViews() {
        setTitle()
        view.backgroundColor = .white
        
        addFilterButton()
        
        searchBar.delegate = self
        searchBar.placeholder = "Enter Event Name..."
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

            /// Create the label
            let label = UILabel()
            label.text = "Event Visualizer"
            label.sizeToFit()
            label.center = navView.center
            label.textAlignment = NSTextAlignment.center
            /// Create the image view
            let image = UIImageView()
            image.image = UIImage(systemName: "wrench.and.screwdriver")
            // To maintain the image's aspect ratio:
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
            title = "Event Visualizer"
        }
    }
    
    private func addFilterButton() {
        let rightButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(actionForFilter))
        
        let leftButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(backAction))

        self.navigationItem.rightBarButtonItem = rightButtonItem
        self.navigationItem.leftBarButtonItem = leftButtonItem
    }
    
    private func addResetFilterButton() {
        let rightButtonItem = UIBarButtonItem(title: "Reset Filter", style: .plain, target: self, action: #selector(actionForResetFilter))

        self.navigationItem.rightBarButtonItem = rightButtonItem
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
    
    // MARK: - actions handler
    
    @objc private func searchBarClearButtonDidTap(_ clearButton: UIButton) {
        searchBar.endEditing(true)
    }
    
    @objc private func backAction(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func actionForFilter(sender: UIBarButtonItem) {

        let viewController = FilterViewController()
        viewController.filterDelegate = self
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc private func actionForResetFilter(sender: UIBarButtonItem) {
        filterSelected = []
        viewModel.filterResult = filterSelected
        addFilterButton()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension EventVisualizerLandingViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.tableView {
            tableView.deselectRow(at: indexPath, animated: true)
            if let (selectedEventName, events) = viewModel.didSelectRow(at: indexPath) {
                showEventListView(selectedEventName, events)
            }
        } else {
            if let cell = tableView.cellForRow(at: indexPath) as? RadioLabelTableViewCell {
                let filterName = "\(cell.nameLabel.text ?? "")"
                if let indexOfName = filterSelected.firstIndex(of: filterName) {
                    filterSelected.remove(at: indexOfName)
                } else {
                    filterSelected.append(filterName)
                }
                cell.setUpSelectedCell()
            }
        }

    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
}

// MARK: - UITableViewDataSource

extension EventVisualizerLandingViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.tableView {
            return viewModel.sectionCount
        } else {
            return 1
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return viewModel.cellsCount(section: section)
        } else {
          return viewModel.sectionCount
        }
        
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableView {
            let cell = tableView.dequeueReusableCell() as EventsListingTableViewCell
            cell.apply(viewModel.cellViewModel(for: indexPath))
            return cell
        } else {
            let cell = tableView.dequeueReusableCell() as RadioLabelTableViewCell
            cell.nameLabel.text = viewModel.headerTitle(section: indexPath.row)
            cell.selectionStyle = .none
            if filterSelected.contains(viewModel.headerTitle(section: indexPath.row)) {
                cell.isEnabled = true
            } else {
                cell.isEnabled = false
            }
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == self.tableView {
            return viewModel.headerTitle(section: section)
        } else {
            return nil
        }
    }
    
    func showEventListView(_ selectedEventName: String, _ eventDict: [Message]) {
        let viewController = EventsListViewController()
        viewController.selectedEventName = selectedEventName
        viewController.eventDict = eventDict
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
        
    }
}

extension EventVisualizerLandingViewController: UISearchBarDelegate {

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

extension EventVisualizerLandingViewController: FilterDataProtocol {
    func sendUserInput(data: [(String, String)]) {
        self.filterSelected = viewModel.getFilteredEvents(data: data)
        viewModel.filterResult = self.filterSelected
        if !filterSelected.isEmpty {
            addResetFilterButton()
        }
        tableView.reloadData()
    }
}
