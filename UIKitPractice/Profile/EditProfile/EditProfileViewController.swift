//
//  EditProfileViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit

final class EditProfileViewController: UIViewController {
    
    private let rootView = EditProfileView()
    private let viewModel: EditProfileViewModel
    
    init(viewModel: EditProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("edit_profile.title")

        view.backgroundColor = .systemBackground
        
        rootView.nameField.text = viewModel.name
        rootView.emailField.text = viewModel.email
        
        rootView.saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }
    
    @objc private func saveTapped() {
        view.endEditing(true)
        
        viewModel.saveChanges(
            name: rootView.nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            email: rootView.emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        )
        
        // Показываем успех
        let alert = UIAlertController(title: L10n.tr("common.ready"), message: L10n.tr("edit_profile.saved"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("common.ok"), style: .default))
        present(alert, animated: true)
        
        // Возвращаемся назад
        navigationController?.popViewController(animated: true)
    }
}
