//
//  WelcomeCoordinator.swift .swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit

final class WelcomeCoordinator: Coordinator {
    
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    var onFinish: (() -> Void)?   // Сообщаем AppCoordinator что экран Welcome окончен
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let viewModel = WelcomeViewModel()
        
        viewModel.onLogin = { [weak self] in
            print("WelcomeCoordinator: onLogin")
            self?.finish()
        }
        
        let vc = WelcomeViewController(viewModel: viewModel)
        vc.title = "Welcome"

        navigationController.setViewControllers([vc], animated: false)
    }
    
    private func finish() {
        onFinish?()   // передаём AppCoordinator → он запустит LoginCoordinator
    }
}
