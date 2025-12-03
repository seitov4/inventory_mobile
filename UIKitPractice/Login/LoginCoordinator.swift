//
//  LoginCoordinator.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 21.11.2025.
//

import UIKit

final class LoginCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    var onFinish: (() -> Void)?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = LoginViewModel()
        viewModel.onLoginSuccess = { [weak self] in
            print("LoginCoordinator: login success")
            self?.onFinish?()
        }

        let vc = LoginViewController(viewModel: viewModel)
        navigationController.setViewControllers([vc], animated: false)
    }
}

