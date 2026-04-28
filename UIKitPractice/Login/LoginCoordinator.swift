//
//  LoginCoordinator.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 21.11.2025.
//

import UIKit
import SwiftUI

final class LoginCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    var onFinish: (() -> Void)?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vm = LoginScreenViewModel()
        let view = LoginScreen(viewModel: vm) { [weak self] in
            self?.onFinish?()
        }
        let vc = UIHostingController(rootView: view)
        navigationController.setViewControllers([vc], animated: false)
    }
}

