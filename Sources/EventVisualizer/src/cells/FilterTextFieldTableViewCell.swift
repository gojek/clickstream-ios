//
//  FilterTextFieldTableViewCell.swift
//  SettingsKit
//
//  Created by Rishav Gupta on 22/03/22.
//  Copyright © 2022 PT GoJek Indonesia. All rights reserved.
//

#if EVENT_VISUALIZER_ENABLED
import UIKit

protocol UserFilterDelegate {
    func updateKeyPair(key: String, index: Int)
    func updateValuePair(value: String, index: Int)
}

final class FilterTextFieldTableViewCell: UITableViewCell, ReusableView, NibLoadableView  {

    private let keyTextField: UITextField = UITextField()
    private let valueTextField: UITextField = UITextField()
    private let horizontalStackView: UIStackView = UIStackView()
    
    var indexForCell: Int?
    var filterDelegate: UserFilterDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpViews() {
        contentView.addSubview(horizontalStackView)
        horizontalStackView.addArrangedSubview(keyTextField)
        horizontalStackView.addArrangedSubview(valueTextField)
        
        NSLayoutConstraint.activate([
            horizontalStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4.0),
            horizontalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4.0),
            horizontalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            horizontalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        keyTextField.placeholder = "Key"
        valueTextField.placeholder = "Value"
        
        keyTextField.delegate = self
        valueTextField.delegate = self
        
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.spacing = 4.0
        horizontalStackView.isLayoutMarginsRelativeArrangement = true
        horizontalStackView.layoutMargins = UIEdgeInsets(top: 12.0, left: 16.0, bottom: 12.0, right: 24.0)
        horizontalStackView.axis = .horizontal
    }
    
    func configureCells(key: String, value: String) {
        keyTextField.text = key
        valueTextField.text = value
    }
}

extension FilterTextFieldTableViewCell: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            if textField == keyTextField, let index = indexForCell {
                filterDelegate?.updateKeyPair(key: updatedText, index: index)
            } else if textField == valueTextField, let index = indexForCell {
                filterDelegate?.updateValuePair(value: updatedText, index: index)
            }
        }
        return true
    }
}
#endif
