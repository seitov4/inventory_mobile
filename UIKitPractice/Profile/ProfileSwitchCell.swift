//
//  ProfileSwitchCell.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit

final class ProfileSwitchCell: UITableViewCell {
    static let reuseIdentifier = "ProfileSwitchCell"

    private let toggleSwitch = UISwitch()
    var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView = toggleSwitch
        toggleSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    @objc private func switchChanged() {
        onToggle?(toggleSwitch.isOn)
    }

    func configure(icon: UIImage?, title: String, isOn: Bool) {
        var cfg = defaultContentConfiguration()
        cfg.text = title
        cfg.image = icon
        contentConfiguration = cfg
        toggleSwitch.setOn(isOn, animated: true)
    }
}
