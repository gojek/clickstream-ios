//
//  FilterViewController.swift
//  SettingsKit
//
//  Created by Rishav Gupta on 22/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

#if EVENT_VISUALIZER_ENABLED
import UIKit

protocol FilterDataProtocol {
    func sendUserInput(data: [(String, String)])
}

final class FilterViewController: UIViewController {

    private let tableView: UITableView = UITableView()
    private let addCellButton: UIButton = UIButton()
    private let applyFilter: UIButton = UIButton()
    
    var filterDelegate: FilterDataProtocol?
    private var noOfCells: Int = 1
    private var typedArray: [(String, String)] = [("", "")]
    
    // MARK: - View Life Cycle
    override func loadView() {
        view = UIView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViews()
        setUpLayout()
    }
    
    private func setUpViews() {
        title = "Filter"

        view.backgroundColor = .white
        
        applyFilter.setTitle("Apply Filter", for: .normal)
        applyFilter.backgroundColor = .systemBlue
        applyFilter.addTarget(self, action: #selector(self.applyFilterClicked(sender:)), for: .touchUpInside)
        
        if #available(iOS 13.0, *) {
            addCellButton.setImage(UIImage(systemName: "plus"), for: .normal)
        } else {
            addCellButton.setTitle("Add Row", for: .normal)
        }
        addCellButton.addTarget(self, action: #selector(self.addCellClicked(sender:)), for: .touchUpInside)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.register(FilterTextFieldTableViewCell.self)
    }
    
    private func setUpLayout() {
        view.addSubview(tableView)
        view.addSubview(applyFilter)
        view.addSubview(addCellButton)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 150),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            applyFilter.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            applyFilter.heightAnchor.constraint(equalToConstant: 40),
            applyFilter.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            applyFilter.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            addCellButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            addCellButton.heightAnchor.constraint(equalToConstant: 40),
            addCellButton.widthAnchor.constraint(equalToConstant: 40),
            addCellButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10)
        ])
        tableView.translatesAutoresizingMaskIntoConstraints = false
        applyFilter.translatesAutoresizingMaskIntoConstraints = false
        addCellButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    @objc func applyFilterClicked(sender: UIButton){
        filterDelegate?.sendUserInput(data: typedArray)
        navigationController?.popViewController(animated: true)
    }
    
    @objc func addCellClicked(sender: UIButton){
        let lastKey = typedArray[noOfCells - 1].0
        let lastValue = typedArray[noOfCells - 1].1
        if lastKey == "" && lastValue == "" {
            return
        }
        /// appending a new element in the array with empty variables
        typedArray.append(("", ""))
        noOfCells += 1
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension FilterViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell() as FilterTextFieldTableViewCell
        cell.indexForCell = indexPath.row
        cell.filterDelegate = self
        if indexPath.row < typedArray.count {
            cell.configureCells(key: typedArray[indexPath.row].0, value: typedArray[indexPath.row].1)
        } else {
            cell.configureCells(key: "", value: "")
        }
        return cell
        
    }
}

extension FilterViewController: UserFilterDelegate {
    func updateKeyPair(key: String, index: Int) {
        typedArray[index].0 = key
    }
    
    func updateValuePair(value: String, index: Int) {
        typedArray[index].1 = value
    }
}
#endif
