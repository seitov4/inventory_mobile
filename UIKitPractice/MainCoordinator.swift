//
//  Untitled.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit

final class MainCoordinator: NSObject, Coordinator {

    private let window: UIWindow
    var childCoordinators: [Coordinator] = []

    private var profileCoordinator: ProfileCoordinator?

    init(window: UIWindow) {
        self.window = window
        super.init()
    }

    func start() {

        // MARK: - NavigationControllers
        let analyticsNav = UINavigationController()
        let analytics = AnalyticsCoordinator(navigationController: analyticsNav)
        analytics.start()
        childCoordinators.append(analytics)

        let productsNav = UINavigationController()
        let products = ProductsCoordinator(navigationController: productsNav)
        products.start()
        childCoordinators.append(products)

        let quickNav = UINavigationController()
        let quick = QuickSaleCoordinator(navigationController: quickNav)
        quick.start()
        childCoordinators.append(quick)

        let notificationsNav = UINavigationController()
        let notifications = NotificationsCoordinator(navigationController: notificationsNav)
        notifications.start()
        childCoordinators.append(notifications)

        let profileNav = UINavigationController()
        let profile = ProfileCoordinator(window: window, navigationController: profileNav)
        profile.start()
        childCoordinators.append(profile)
        profileCoordinator = profile

        // MARK: - TabBarController
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            createTab(nav: analyticsNav, title: "Аналитика", image: "chart.bar.fill", tag: 0),
            createTab(nav: productsNav, title: "Товары", image: "cube.fill", tag: 1),
            createTab(nav: quickNav, title: "Продажа", image: "qrcode.viewfinder", tag: 2),
            createTab(nav: notificationsNav, title: "Уведомления", image: "bell.fill", tag: 3),
            createTab(nav: profileNav, title: "Профиль", image: "person.fill", tag: 4)
        ]

        // MARK: - TabBar Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground

        let titleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
        let normalTitle: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: titleFont
        ]
        let selectedTitle: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemBlue,
            .font: titleFont
        ]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalTitle
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedTitle
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = .zero
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = .zero

        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue

        appearance.shadowColor = .clear
        appearance.backgroundEffect = nil

        tabBarController.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }

        tabBarController.tabBar.isSpringLoaded = false
        tabBarController.tabBar.selectionIndicatorImage = UIImage()
        tabBarController.tabBar.itemPositioning = .fill

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        ThemeManager.shared.applySavedTheme()
    }

    private func createTab(nav: UINavigationController, title: String, image: String, tag: Int) -> UINavigationController {
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        let image = UIImage(systemName: image)?.withConfiguration(config)

        let item = UITabBarItem(
            title: title,
            image: image,
            selectedImage: image
        )

        item.tag = tag

        nav.tabBarItem = item
        return nav
    }
}
