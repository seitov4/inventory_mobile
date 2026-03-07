//
//  EditProfileDetailsViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import Foundation
import UIKit

// Если у тебя уже есть структура UserData в другом файле — просто удали эту
// Если нет — оставь эту
struct UserData {
    let name: String
    let surname: String
    let age: String
    let position: String
    let store: String
    let email: String
}

final class EditProfileDetailsViewController: UIViewController {

    private let userData: UserData
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    init(userData: UserData) {
        self.userData = userData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Личные данные"
        view.backgroundColor = .systemBackground
        setupUI()
        populateData()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func populateData() {
        let fields = [
            ("Имя", userData.name),
            ("Фамилия", userData.surname),
            ("Возраст", userData.age),
            ("Должность", userData.position),
            ("Магазин", userData.store),
            ("Email", userData.email)
        ]

        for (title, value) in fields {
            let card = createCard(title: title, value: value)
            stackView.addArrangedSubview(card)
        }
    }

    private func createCard(title: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 0.4
        container.layer.borderColor = UIColor.separator.cgColor  // ИСПРАВЛЕНО: .cgColor

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0

        let vStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        vStack.axis = .vertical
        vStack.spacing = 6
        vStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            vStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            vStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            vStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18)
        ])

        // Чтобы карточка не сжималась
        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 76).isActive = true

        return container
    }
}
