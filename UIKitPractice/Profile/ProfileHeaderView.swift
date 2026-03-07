//
//  ProfileHeaderView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit

final class ProfileHeaderView: UIView {

    var onEditTapped: (() -> Void)?
    var onAvatarTapped: (() -> Void)?

    private let avatarImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        iv.contentMode = .scaleAspectFill
        iv.tintColor = .systemGray
        iv.layer.cornerRadius = 48
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let editButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(emailLabel)
        addSubview(editButton)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarImageView.topAnchor.constraint(equalTo: topAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 96),
            avatarImageView.heightAnchor.constraint(equalToConstant: 96),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            editButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            editButton.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor)
        ])

        nameLabel.font = .boldSystemFont(ofSize: 18)
        emailLabel.font = .systemFont(ofSize: 14)
        emailLabel.textColor = .secondaryLabel

        editButton.setTitle("Редактировать", for: .normal)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarImageView.addGestureRecognizer(tap)
    }

    func configure(name: String, email: String?) {
        nameLabel.text = name
        emailLabel.text = email
    }

    func updateAvatar(image: UIImage) {
        avatarImageView.image = image
    }

    @objc private func editTapped() { onEditTapped?() }
    @objc private func avatarTapped() { onAvatarTapped?() }
}
