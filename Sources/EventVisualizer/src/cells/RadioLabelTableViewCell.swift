//
//  RadioLabelTableViewCell.swift
//  SettingsKit
//
//  Created by Rishav Gupta on 15/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

import UIKit

final class RadioLabelTableViewCell: UITableViewCell, ReusableView, NibLoadableView  {
    
    let nameLabel: UILabel = UILabel()
    private let radioButton: UIButton = UIButton()
    private let verticalStackView: UIStackView = UIStackView()
    
    var isEnabled: Bool = false

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
        verticalStackView.addArrangedSubview(radioButton)
        verticalStackView.addArrangedSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4.0),
            verticalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4.0),
            verticalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            radioButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            radioButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4.0),
            radioButton.widthAnchor.constraint(equalToConstant: 50),
            radioButton.heightAnchor.constraint(equalToConstant: 40),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0)
        ])

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 16.0, weight: .medium)
        nameLabel.numberOfLines = 0

        radioButton.translatesAutoresizingMaskIntoConstraints = false

        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.spacing = 4.0
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.layoutMargins = UIEdgeInsets(top: 12.0, left: 16.0, bottom: 12.0, right: 24.0)
        verticalStackView.axis = .horizontal

        accessoryType = .disclosureIndicator
        
        if isEnabled {
            contentView.backgroundColor = .gray
        } else {
            contentView.backgroundColor = .none
        }
    }
    
    func setUpSelectedCell() {
        if isEnabled {
            contentView.backgroundColor = .none
            isEnabled = false
        } else {
            contentView.backgroundColor = .gray
            isEnabled = true
        }
    }
}
