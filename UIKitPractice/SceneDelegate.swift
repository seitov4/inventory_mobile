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
        ThemeManager.shared.applySavedTheme()

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        if let shortcutItem = connectionOptions.shortcutItem,
           let route = AppShortcutRoute(shortcutType: shortcutItem.type) {
            AppShortcutRouter.shared.pendingRoute = route
        }

        // Запуск AppCoordinator (Auth flow -> Main)
        appCoordinator = AppCoordinator(window: window)
        appCoordinator?.start()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        print("App opened with URL:", url.absoluteString)
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
        AppShortcutRouter.shared.pendingRoute = route
        NotificationCenter.default.post(name: .appShortcutTriggered, object: route)
        completionHandler(true)
    }
}



