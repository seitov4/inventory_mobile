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

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupActions()
        bindViewModel()
        rootView.emailField.delegate = self
    }
    
    private func setupActions() {
        rootView.emailField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
                rootView.passwordField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)

                rootView.loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        rootView.forgorPasswordButton.addTarget(self, action: #selector(forgotTapped), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        viewModel.onValidationChanged = { [weak self] isEmailValid, isPasswordValid in
            guard let self = self else { return }
            
            self.rootView.showEmailError(isEmailValid ? nil : "Некорректный email")
            self.rootView.showPasswordError(isPasswordValid ? nil : "Пароль состоит минимум из 8 символов и цифры")
            
            let enabled = isEmailValid && isPasswordValid
            self.rootView.setLoginEnabled(enabled)
        }
        
          }
    
    @objc private func emailChanged() {
        viewModel.validateEmail(rootView.emailField.text)
    }
    
    @objc private func passwordChanged() {
        viewModel.validatePassword(rootView.passwordField.text)
    }
    
    @objc private func loginTapped() {
        view.endEditing(true)
        viewModel.login(email: rootView.emailField.text, password: rootView.passwordField.text)
        
        if !(viewModel.isEmailValid && viewModel.isPasswordValid) {
            rootView.emailField.shake()
            rootView.passwordField.shake()
            return
        }
    }
    
    @objc private func forgotTapped () {
        print ("Forgot password tapped")
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        // Запрещаем пробелы для email
        if textField == rootView.emailField {
            return !string.contains(" ")
        }
        return true
    }
}
