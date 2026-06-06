//
//  SceneDelegate.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 05.11.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        ThemeManager.shared.applySavedTheme(to: window)
        self.window = window

        if let shortcutItem = connectionOptions.shortcutItem,
           let route = AppShortcutRoute(shortcutType: shortcutItem.type) {
            AppShortcutRouter.shared.enqueue(route)
        }

        if let url = connectionOptions.urlContexts.first?.url,
           let route = AppShortcutRoute(deepLink: url) {
            AppShortcutRouter.shared.enqueue(route)
        }

        if let route = connectionOptions.userActivities.compactMap(makeRoute(from:)).first {
            AppShortcutRouter.shared.enqueue(route)
        }

        AppShortcutRouter.shared.reloadPersistedRouteIfNeeded()

        // Запуск AppCoordinator (Auth flow -> Main)
        appCoordinator = AppCoordinator(window: window)
        appCoordinator?.start()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        AppShortcutRouter.shared.reloadPersistedRouteIfNeeded()
        guard let route = AppShortcutRouter.shared.pendingRoute else { return }
        NotificationCenter.default.post(name: .appShortcutTriggered, object: route)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        guard let route = AppShortcutRoute(deepLink: url) else {
            print("App opened with URL:", url.absoluteString)
            return
        }

        AppShortcutRouter.shared.enqueue(route)
        NotificationCenter.default.post(name: .appShortcutTriggered, object: route)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let route = makeRoute(from: userActivity) else { return }
        AppShortcutRouter.shared.enqueue(route)
        NotificationCenter.default.post(name: .appShortcutTriggered, object: route)
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard let route = AppShortcutRoute(shortcutType: shortcutItem.type) else {
            completionHandler(false)
            return
        }
        AppShortcutRouter.shared.enqueue(route)
        NotificationCenter.default.post(name: .appShortcutTriggered, object: route)
        completionHandler(true)
    }

    private func makeRoute(from userActivity: NSUserActivity) -> AppShortcutRoute? {
        if let targetContentIdentifier = userActivity.targetContentIdentifier,
           let route = AppShortcutRoute(identifier: targetContentIdentifier) {
            return route
        }

        if let routeValue = userActivity.userInfo?["route"] as? String,
           let route = AppShortcutRoute(identifier: routeValue) {
            return route
        }

        return nil
    }
}
