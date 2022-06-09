//
//  EventsListingTableViewCell.swift
//  Launchpad
//
//  Created by Rishav Gupta on 08/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import UIKit

protocol ViewModelApplicable {
    
    associatedtype ViewModel
    
    func apply(_ viewModel: ViewModel)
}

final class EventsListingTableViewCell: UITableViewCell, ReusableView, NibLoadableView {
    
    let nameLabel: UILabel = UILabel()
    private let changedConfigLabel: UILabel = UILabel()
    private let allConfigLabel: UILabel = UILabel()
    private let verticalStackView: UIStackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        contentView.addSubview(verticalStackView)
        contentView.addSubview(allConfigLabel)
        verticalStackView.addArrangedSubview(nameLabel)
        verticalStackView.addArrangedSubview(changedConfigLabel)

        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4.0),
            verticalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4.0),
            verticalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            verticalStackView.centerYAnchor.constraint(equalTo: allConfigLabel.centerYAnchor),
            allConfigLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12.0),
            changedConfigLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12.0)
        ])

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 16.0, weight: .medium)
        nameLabel.numberOfLines = 0

        changedConfigLabel.translatesAutoresizingMaskIntoConstraints = false
        changedConfigLabel.font = .systemFont(ofSize: 12.0, weight: .light)
        changedConfigLabel.textColor = .red
        changedConfigLabel.numberOfLines = 0

        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.spacing = 4.0
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.layoutMargins = UIEdgeInsets(top: 12.0, left: 16.0, bottom: 12.0, right: 24.0)
        verticalStackView.axis = .vertical

        allConfigLabel.translatesAutoresizingMaskIntoConstraints = false
        allConfigLabel.textColor = .white

        accessoryType = .disclosureIndicator
    }
}

extension EventsListingTableViewCell: ViewModelApplicable {
    func apply(_ viewModel: ViewModel) {
        nameLabel.text = viewModel.name
        changedConfigLabel.text = viewModel.changedConfigsCount
        allConfigLabel.text = "\(viewModel.availableConfigsCount)"
    }
}

extension EventsListingTableViewCell {
    struct ViewModel {
        let name: String
        let changedConfigsCount: String
        let availableConfigsCount: String
    }
}
