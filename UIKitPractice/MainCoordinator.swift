//
//  Untitled.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit

final class MainCoordinator: Coordinator {
    let navigationController: UINavigationController
    // для соответствия протоколу
    private let window: UIWindow
    var childCoordinators: [Coordinator] = []

    init(window: UIWindow) {
        self.window = window
        // этот navigationController не будет видим; у нас будет TabBar как root
        self.navigationController = UINavigationController()

    }

    func start() {
        let tabBar = UITabBarController()
        tabBar.view.backgroundColor = .systemBackground

        // 1) Dashboard
        let dashboardNav = UINavigationController()
        let dashboardCoord = DashboardCoordinator(navigationController: dashboardNav)
        childCoordinators.append(dashboardCoord)
        dashboardCoord.start()
        if let dashboardRoot = dashboardNav.viewControllers.first {
            dashboardRoot.tabBarItem = UITabBarItem(title: "Главная", image: UIImage(systemName: "chart.bar"), tag: 0)
        }

        // 2) Reports (заглушка)
        let reportsNav = UINavigationController()
        let reportsVC = UIViewController()
        reportsVC.view.backgroundColor = .systemBackground
        reportsVC.title = "Отчёты"
        reportsVC.tabBarItem = UITabBarItem(title: "Отчёты", image: UIImage(systemName: "doc.text"), tag: 1)
        reportsNav.setViewControllers([reportsVC], animated: false)

        // 3) Profile
        let profileNav = UINavigationController()
        let profileCoord = ProfileCoordinator(navigationController: profileNav)
        
        profileCoord.onLogout = {[weak self] in
            self?.logout()
        }
        childCoordinators.append(profileCoord)
        profileCoord.start()

        
        if let profileRoot = profileNav.viewControllers.first {
            profileRoot.tabBarItem = UITabBarItem(title: "Профиль", image: UIImage(systemName: "person"), tag: 2)
        }

        tabBar.setViewControllers([dashboardNav, reportsNav, profileNav], animated: false)

        // Устанавливаем TabBar как root окна
        window.rootViewController = tabBar
        window.makeKeyAndVisible()
    }
    private func logout() {
        childCoordinators.removeAll()

        let appCoordinator = AppCoordinator(window: window)
        childCoordinators.append(appCoordinator)
        appCoordinator.start()
    }
}


