//
//  LoginViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 21.11.2025.
//

import Foundation

final class LoginViewModel {

    var onLoginSuccess: (() -> Void)?
    var onLoginFailure: ((_ error: String) -> Void)?

    private let authService = AuthService()

    func login(email: String?, password: String?) {

        guard let email = email, !email.isEmpty else {
            onLoginFailure?("Введите email")
            return
        }

        guard let password = password, !password.isEmpty else {
            onLoginFailure?("Введите пароль")
            return
        }

        authService.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.onLoginSuccess?()

                case .failure(let error):
                    // Показываем сообщение, которое вернёт backend
                    let backendMessage = error.localizedDescription

                    if backendMessage.contains("401") {
                        self?.onLoginFailure?("Неверный email или пароль")
                    } else {
                        self?.onLoginFailure?(backendMessage)
                    }
                }
            }
        }
    }
}
