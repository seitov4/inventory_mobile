//
//  ProfileSegmentCell.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit

final class ProfileSegmentCell: UITableViewCell {
    static let reuseIdentifier = "ProfileSegmentCell"

    // MARK: - Subviews
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .systemBlue
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .label
        l.font = UIFont.preferredFont(forTextStyle: .body)
        l.translatesAutoresizingMaskIntoConstraints = false

        // ВАЖНО: label НЕ должен тянуться
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    let segment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Светлая", "Тёмная", "Системная"])
        sc.translatesAutoresizingMaskIntoConstraints = false

        // Сегмент должен расширяться максимально
        sc.setContentHuggingPriority(.required, for: .horizontal)
        sc.setContentCompressionResistancePriority(.required, for: .horizontal)
        return sc
    }()

    var onSegmentChanged: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupLayout()
        segment.addTarget(self, action: #selector(segChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
        segment.addTarget(self, action: #selector(segChanged), for: .valueChanged)
    }

    private func setupLayout() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(segment)

        let margin = contentView.layoutMarginsGuide

        // ВАЖНО: правильные приоритеты
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        segment.setContentHuggingPriority(.defaultLow, for: .horizontal)
        segment.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: margin.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),

            segment.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16),
            segment.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
            segment.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: segment.leadingAnchor, constant: -12)
        ])
    }

    func configure(icon: UIImage?, title: String, selectedIndex: Int) {
        iconImageView.image = icon
        titleLabel.text = title
        segment.selectedSegmentIndex = selectedIndex
    }

    @objc private func segChanged() {
        onSegmentChanged?(segment.selectedSegmentIndex)
    }
}
