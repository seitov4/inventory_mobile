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
        title = L10n.tr("Личные данные")
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = true

        contentView.onLogoutTapped = { [weak self] in
            self?.showLogoutAlert()
        }
        
        contentView.update(with: [
            (L10n.tr("personal.name"), L10n.tr("personal.your_name")),
            (L10n.tr("personal.age"), "22"),
            (L10n.tr("personal.store"), "TechShop"),
            (L10n.tr("Должность"), L10n.tr("personal.manager")),
            ("Email", "test@mail.com"),
            (L10n.tr("Телефон"), "+7700 123 45 67")
        ])
    }
    private func showLogoutAlert() {
        let alert = UIAlertController(
            title: L10n.tr("profile.logout_title"),
            message: L10n.tr("profile.logout_message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("common.logout"), style: .destructive) { [weak self] _ in
            self?.onLogout?()
        })

        present(alert, animated: true)
    }
    
}
