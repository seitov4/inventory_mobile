//
//  LoginViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 21.11.2025.
//

import UIKit
import LocalAuthentication
import Security

final class LoginViewController: UIViewController {

    private let rootView = LoginView()
    private let viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        setupActions()
        bindViewModel()
    }

    private func setupActions() {
        rootView.loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        rootView.loginField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        rootView.passwordField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    private func bindViewModel() {
            viewModel.onLoginFailure = { [weak self] message in
                guard let self else { return }

                let field = message.contains("пароль")
                    ? self.rootView.passwordField
                    : self.rootView.loginField

                self.rootView.showError(message: message, on: field)
            }
        }


    @objc private func loginTapped() {
        view.endEditing(true)

        viewModel.login(
            login: rootView.loginField.text,
            password: rootView.passwordField.text,
            type: rootView.loginType
        )
    }

    @objc private func textDidChange() {
        rootView.clearError()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
