//
//  AppCoordinator.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit
import SwiftUI

final class AppCoordinator: Coordinator {

    private let window: UIWindow
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    private let authManager = AuthManager.shared
    private var mainCoordinator: MainCoordinator?

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShortcutNotification(_:)),
            name: .appShortcutTriggered,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        routeInitial()
    }

    private func routeInitial() {
        // If there is no backend session token -> show account login.
        guard KeychainManager.shared.getToken() != nil else {
            startLogin()
            return
        }

        // Token exists. If app passcode is not set yet, require it now.
        guard authManager.hasPasscode else {
            startPasscodeSetup()
            return
        }

        // Token + passcode exist -> lock screen on launches.
        startUnlock()
    }

    private func startLogin() {
        let login = LoginCoordinator(navigationController: navigationController)
        childCoordinators = [login]

        login.onFinish = { [weak self] in
            guard let self else { return }
            if self.authManager.hasPasscode {
                // Ask for biometrics preference after a successful account login if user hasn't decided yet.
                if self.authManager.biometricPreference == .unknown {
                    self.startBiometricsPromptThenMain()
                } else {
                    self.startMainFlow()
                }
            } else {
                self.startPasscodeSetup()
            }
        }

        login.start()
    }

    private func startPasscodeSetup() {
        let vm = PasscodeSetupViewModel(authManager: authManager, isExistingUser: false)
        let view = PasscodeSetupScreen(viewModel: vm) { [weak self] in
            self?.startMainFlow()
        }
        let vc = UIHostingController(rootView: view)
        vc.title = "Код-пароль"
        transitionTo([vc])
    }

    private func startUnlock() {
        let vm = PasscodeUnlockViewModel(authManager: authManager)
        let view = PasscodeUnlockScreen(
            viewModel: vm,
            onUnlocked: { [weak self] in self?.startMainFlow() },
            onLockout: { [weak self] in self?.startLogin() }
        )
        let vc = UIHostingController(rootView: view)
        vc.title = "Разблокировка"
        transitionTo([vc])
    }

    private func startMainFlow() {
        let main = MainCoordinator(window: window)
        mainCoordinator = main
        childCoordinators = [main]
        main.start()
        if let route = AppShortcutRouter.shared.pendingRoute {
            main.openShortcut(route)
            AppShortcutRouter.shared.pendingRoute = nil
        }
    }

    private func startBiometricsPromptThenMain() {
        let view = BiometricsOptInPrompt(authManager: authManager) { [weak self] in
            self?.startMainFlow()
        }
        let vc = UIHostingController(rootView: view)
        transitionTo([vc])
    }

    private func transitionTo(_ viewControllers: [UIViewController]) {
        UIView.transition(
            with: navigationController.view,
            duration: 0.35,
            options: [.transitionCrossDissolve, .curveEaseInOut]
        ) {
            self.navigationController.setViewControllers(viewControllers, animated: false)
        }
    }

    @objc
    private func handleShortcutNotification(_ notification: Notification) {
        guard let route = notification.object as? AppShortcutRoute else { return }
        if let mainCoordinator {
            mainCoordinator.openShortcut(route)
            AppShortcutRouter.shared.pendingRoute = nil
        }
    }
}
