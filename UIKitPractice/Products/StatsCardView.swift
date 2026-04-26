//
//  StatsCardView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 25.01.2026.
//

import UIKit

 final class StatsCardView: UIView {
    private let iconImageView = UIImageView()
    private let valueLabel = UILabel()
    private let labelLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        layer.cornerRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        applyShadow()

        iconImageView.contentMode = .scaleAspectFit
        
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        labelLabel.font = .systemFont(ofSize: 14, weight: .medium)
        
        let stack = UIStackView(arrangedSubviews: [iconImageView, valueLabel, labelLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyShadow()
        }
    }

    private func applyShadow() {
        layer.shadowColor = UIColor.adaptiveCardShadowBase()
            .resolvedColor(with: traitCollection)
            .cgColor
        layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.45 : 0.18
    }

    func configure(
        icon: String,
        value: String,
        label: String,
        backgroundColor: UIColor,
        iconColor: UIColor,
        valueColor: UIColor,
        labelColor: UIColor
    ) {
        self.backgroundColor = backgroundColor
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = iconColor
        valueLabel.text = value
        valueLabel.textColor = valueColor
        labelLabel.text = label
        labelLabel.textColor = labelColor
    }
    
    func updateValue(_ value: String) {
        valueLabel.text = value
    }
}
