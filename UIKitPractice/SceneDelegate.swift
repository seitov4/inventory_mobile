//
//  SceneDelegate.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 05.11.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let appCoordinator = AppCoordinator(window: window)
        self.coordinator = appCoordinator
        appCoordinator.start()
        self.window = window
    }
}


