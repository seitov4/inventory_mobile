//
//  ProfileCoordinator.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 18.11.2025.
//


import UIKit

final class ProfileCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    var onLogout: (() -> Void)?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vm = ProfileViewModel()
        let vc = ProfileViewController(viewModel: vm)
        
        vm.onLogout = { [weak self] in
            self?.showLogoutAlert()
        }
        
        vc.title = "Профиль"
        navigationController.setViewControllers([vc], animated: false)
    }
    
    private func showLogoutAlert() {
        let alert = UIAlertController(
            title: "Выход",
            message: "Вы действительно хотите выйти из аккаунта?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))

        alert.addAction(UIAlertAction(title: "Да", style: .destructive, handler: { [weak self] _ in
            self?.onLogout?()
        }))

        navigationController.present(alert, animated: true)
    }

}

