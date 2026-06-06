//
//  Untitled.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit
import SwiftUI

final class MainCoordinator: NSObject, Coordinator {

    private let window: UIWindow
    var childCoordinators: [Coordinator] = []

    private var profileCoordinator: ProfileCoordinator?
    private var tabBarController: UITabBarController?
    private var analyticsNavController: UINavigationController?
    private var productsNavController: UINavigationController?
    private var quickNavController: UINavigationController?
    private var notificationsNavController: UINavigationController?
    private var profileNavController: UINavigationController?
    private var navigationControllersByTab: [AppTab: UINavigationController] = [:]

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
        analyticsNavController = analyticsNav

        let productsNav = UINavigationController()
        let products = ProductsCoordinator(navigationController: productsNav)
        products.start()
        childCoordinators.append(products)
        productsNavController = productsNav

        let quickNav = UINavigationController()
        let quick = QuickSaleCoordinator(navigationController: quickNav)
        quick.start()
        childCoordinators.append(quick)
        quickNavController = quickNav

        let notificationsNav = UINavigationController()
        let notifications = NotificationsCoordinator(navigationController: notificationsNav)
        notifications.start()
        childCoordinators.append(notifications)
        notificationsNavController = notificationsNav

        let profileNav = UINavigationController()
        let profile = ProfileCoordinator(window: window, navigationController: profileNav)
        profile.start()
        childCoordinators.append(profile)
        profileCoordinator = profile
        profileNavController = profileNav

        navigationControllersByTab = [
            .analytics: analyticsNav,
            .products: productsNav,
            .sales: quickNav,
            .notifications: notificationsNav,
            .profile: profileNav
        ]

        // MARK: - TabBarController
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = makeAllowedViewControllers()

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
        self.tabBarController = tabBarController
        observeLanguageChanges()
        observeRoleChanges()

        if window.rootViewController == nil {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        } else {
            UIView.transition(
                with: window,
                duration: 0.35,
                options: [.transitionCrossDissolve, .curveEaseInOut]
            ) {
                self.window.rootViewController = tabBarController
                self.window.makeKeyAndVisible()
            }
        }
        ThemeManager.shared.applySavedTheme()
    }

    @discardableResult
    func openShortcut(_ route: AppShortcutRoute) -> Bool {
        guard tabBarController != nil else { return false }
        switch route {
        case .analytics:
            guard selectTab(.analytics) else { return false }
            analyticsNavController?.popToRootViewController(animated: false)
        case .products:
            guard selectTab(.products) else { return false }
            productsNavController?.popToRootViewController(animated: false)
        case .quickSale:
            guard selectTab(.sales) else { return false }
            quickNavController?.popToRootViewController(animated: false)
        case .notifications:
            guard selectTab(.notifications) else { return false }
            notificationsNavController?.popToRootViewController(animated: false)
        case .myEnterprise:
            guard UserSessionManager.shared.currentRole.canViewEnterprise,
                  selectTab(.profile) else { return false }
            guard let profileNavController else { return false }
            profileNavController.popToRootViewController(animated: false)
            let enterpriseVC = UIHostingController(rootView: MyEnterpriseScreen(viewModel: .backend()))
            profileNavController.pushViewController(enterpriseVC, animated: false)
        }

        return true
    }

    private func makeAllowedViewControllers() -> [UIViewController] {
        UserSessionManager.shared.currentRole.allowedTabs.compactMap { tab in
            guard let nav = navigationControllersByTab[tab] else { return nil }
            return createTab(nav: nav, tab: tab)
        }
    }

    private func createTab(nav: UINavigationController, tab: AppTab) -> UINavigationController {
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        let image = UIImage(systemName: tab.systemImage)?.withConfiguration(config)

        let item = UITabBarItem(
            title: L10n.tr(tab.titleKey),
            image: image,
            selectedImage: image
        )

        item.tag = tab.rawValue

        nav.tabBarItem = item
        return nav
    }

    @discardableResult
    private func selectTab(_ tab: AppTab) -> Bool {
        guard let tabBarController,
              let index = tabBarController.viewControllers?.firstIndex(where: { $0.tabBarItem.tag == tab.rawValue }) else {
            return false
        }
        tabBarController.selectedIndex = index
        return true
    }

    private func observeLanguageChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .appLanguageDidChange,
            object: nil
        )
    }

    private func observeRoleChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(roleDidChange),
            name: .appUserRoleDidChange,
            object: nil
        )
    }

    @objc private func languageDidChange() {
        navigationControllersByTab.forEach { tab, nav in
            nav.tabBarItem.title = L10n.tr(tab.titleKey)
        }
    }

    @objc private func roleDidChange() {
        guard let tabBarController else { return }
        let currentTag = tabBarController.selectedViewController?.tabBarItem.tag
        let viewControllers = makeAllowedViewControllers()
        tabBarController.setViewControllers(viewControllers, animated: true)

        if let currentTag,
           let index = viewControllers.firstIndex(where: { $0.tabBarItem.tag == currentTag }) {
            tabBarController.selectedIndex = index
        } else {
            selectTab(.profile)
        }
    }
}
