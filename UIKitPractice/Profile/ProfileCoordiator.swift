//
//  ProfileCoordiator.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit

final class ProfileCoordinator: Coordinator {

    let navigationController: UINavigationController
    private let window: UIWindow
    var childCoordinators: [Coordinator] = []

    init(window: UIWindow, navigationController: UINavigationController) {
        self.window = window
        self.navigationController = navigationController
    }

    func start() {
        let profileVC = ProfileViewController()

        // ВАЖНО: подключаем ВСЕ переходы
        profileVC.onShowSettings = { [weak self] in
            guard let self else { return }
            let vm = SettingsViewModel()
            let vc = SettingsViewController(viewModel: vm)
            self.navigationController.pushViewController(vc, animated: true)
        }

        profileVC.onShowSupport = { [weak self] in
            guard let self else { return }
            let vc = SupportViewController()
            self.navigationController.pushViewController(vc, animated: true)
        }

        profileVC.onShowEditProfile = { [weak self] in
            guard let self else { return }
            let vm = EditProfileViewModel(name: "Иван Иванов", email: "ivan@example.com")
            let vc = EditProfileViewController(viewModel: vm)
            self.navigationController.pushViewController(vc, animated: true)
        }

        profileVC.onShowProfileDetails = { [weak self] in
            guard let self else { return }
            let vc = PersonalDataViewController()
            vc.onLogout = { [weak self] in
                self?.logout()
            }
            self.navigationController.pushViewController(vc, animated: true)
        }

        profileVC.onLogout = { [weak self] in
            self?.logout()
        }

        navigationController.setViewControllers([profileVC], animated: false)
    }

    private func logout() {
        print("Logout выполнен")
        let appCoordinator = AppCoordinator(window: window)
        childCoordinators.removeAll()
        childCoordinators.append(appCoordinator)
        appCoordinator.start()
    }
}
