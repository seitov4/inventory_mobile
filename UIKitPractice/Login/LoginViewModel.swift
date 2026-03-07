//
//  LoginViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 21.11.2025.
//

import Foundation

final class LoginViewModel {

    var onLoginSuccess: (() -> Void)?
    var onLoginFailure: ((String) -> Void)?

    private let authService = AuthService()

    func login(login: String?, password: String?, type: LoginType) {

        guard let login, !login.isEmpty else {
            onLoginFailure?(type == .email ? "Введите email" : "Введите номер телефона")
            return
        }

        guard let password, !password.isEmpty else {
            onLoginFailure?("Введите пароль")
            return
        }

        authService.login(
            login: login,
            password: password,
            type: type
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.onLoginSuccess?()
                case .failure(let error):
                    self?.onLoginFailure?(error.localizedDescription)
                }
            }
        }
    }



    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}

