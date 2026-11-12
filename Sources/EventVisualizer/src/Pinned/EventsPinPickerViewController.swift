//
//  EventsPinPickerViewController.swift
//  EventVisualizer
//
//  Copyright © 2025 Gojek. All rights reserved.
//

import UIKit

/// Lists the captured event names. Selecting one pushes the regular Event Details
/// screen for that event's latest capture, where a property can be pinned by swiping it.
final class EventsPinPickerViewController: UIViewController {

    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let store: EventsPinnedPropertiesStore
    private var allNames: [String] = []
    private var visibleNames: [String] = []

    init(store: EventsPinnedPropertiesStore = .shared) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pin a property"
        view.backgroundColor = .systemBackground
        if navigationController?.viewControllers.first === self {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done, target: self, action: #selector(handleDone))
        }

        searchBar.delegate = self
        searchBar.placeholder = "Search event name"
        searchBar.autocapitalizationType = .none
        searchBar.searchBarStyle = .minimal
        searchBar.sizeToFit()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = searchBar
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        allNames = store.capturedEventNames()
        applyFilter()
    }

    private static let cellIdentifier = "EventsPinPickerCell"

    private func applyFilter() {
        let query = (searchBar.text ?? "").lowercased()
        visibleNames = query.isEmpty ? allNames : allNames.filter { $0.lowercased().contains(query) }
        tableView.reloadData()
    }

    private func pinnedCount(for eventName: String) -> Int {
        return store.pins.filter { $0.eventName == eventName }.count
    }

    @objc private func handleDone() {
        dismiss(animated: true)
    }
}

extension EventsPinPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Self.cellIdentifier)
        let name = visibleNames[indexPath.row]
        let count = pinnedCount(for: name)
        cell.textLabel?.text = name
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = count == 0 ? "Swipe a property to pin it" : "\(count) pinned"
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension EventsPinPickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let name = visibleNames[indexPath.row]
        guard let event = store.latestEvent(named: name) else { return }
        let details = EventDetailsViewController()
        details.messageSelected = event.msg
        details.pinnedEventName = name
        navigationController?.pushViewController(details, animated: true)
    }
}

extension EventsPinPickerViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilter()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
