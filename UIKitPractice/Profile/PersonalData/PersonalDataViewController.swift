//
//  PersonalDataViewController.swift .swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 07.12.2025.
//

import UIKit

final class PersonalDataViewController: UIViewController {

    private let contentView = PersonalDataView()

    var onLogout: (() -> Void)?

    override func loadView() {
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Личные данные"
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = true

        contentView.onLogoutTapped = { [weak self] in
            self?.showLogoutAlert()
        }
        
        contentView.update(with: [
            ("Имя", "Ваше имя"),
            ("Возраст", "22"),
            ("Магазин", "TechShop"),
            ("Должность", "Менеджер"),
            ("Email", "test@mail.com"),
            ("Телефон", "+7700 123 45 67")
        ])
    }
    private func showLogoutAlert() {
        let alert = UIAlertController(
            title: "Выйти из аккаунта?",
            message: "Вы точно хотите выйти?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            self?.onLogout?()
        })

        present(alert, animated: true)
    }
    
}
