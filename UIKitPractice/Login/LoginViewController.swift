//
//  LoginViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 21.11.2025.
//

import UIKit

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

        setupActions()
        bindViewModel()

        rootView.loginButton.isEnabled = true
        rootView.loginButton.alpha = 1.0
    }

    private func setupActions() {
        rootView.loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        rootView.forgorPasswordButton.addTarget(self, action: #selector(forgotTapped), for: .touchUpInside)
    }

    private func bindViewModel() {
        viewModel.onLoginFailure = { [weak self] error in
            self?.rootView.showGeneralError(error)
        }
    }

    @objc private func loginTapped() {
        view.endEditing(true)
        viewModel.login(
            email: rootView.emailField.text,
            password: rootView.passwordField.text
        )
    }

    @objc private func forgotTapped() {
        print("Forgot password tapped")
    }
}
