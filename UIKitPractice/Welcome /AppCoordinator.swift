//
//  AppCoordinator.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit

final class AppCoordinator: Coordinator {

    private let window: UIWindow
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
    }

    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        startWelcome()
    }

    private func startWelcome() {
        let welcome = WelcomeCoordinator(navigationController: navigationController)
        childCoordinators = [welcome]

        welcome.onFinish = { [weak self] in
            self?.startLogin()
        }

        welcome.start()
    }

    private func startLogin() {
        let login = LoginCoordinator(navigationController: navigationController)
        childCoordinators = [login]

        login.onFinish = { [weak self] in
            self?.startMainFlow()
        }

        login.start()
    }

    private func startMainFlow() {
        let main = MainCoordinator(window: window)
        childCoordinators = [main]
        main.start()
    }
}
