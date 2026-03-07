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
            createTab(nav: analyticsNav, image: "chart.bar.fill", tag: 0),
            createTab(nav: productsNav, image: "cube.fill", tag: 1),
            createTab(nav: quickNav, image: "qrcode.viewfinder", tag: 2),
            createTab(nav: notificationsNav, image: "bell.fill", tag: 3),
            createTab(nav: profileNav, image: "person.fill", tag: 4)
        ]

        // MARK: - TabBar Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground

        let clearTitle: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.clear
        ]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = clearTitle
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = clearTitle
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 100)
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 100)

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
    }

    private func createTab(nav: UINavigationController, image: String, tag: Int) -> UINavigationController {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        let image = UIImage(systemName: image)?.withConfiguration(config)

        let item = UITabBarItem(
            title: "",
            image: image,
            selectedImage: image
        )

        item.imageInsets = .zero
        item.tag = tag

        nav.tabBarItem = item
        return nav
    }
}
