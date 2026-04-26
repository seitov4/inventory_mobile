//
//  NotificationsCoordinator.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 10.12.2025.
//

import Foundation
import UIKit

final class NotificationsCoordinator: Coordinator {

    var childCoordinators: [Coordinator] = []
    private let nav: UINavigationController

    init(navigationController: UINavigationController) {
        self.nav = navigationController
    }

    func start() {
        nav.navigationBar.prefersLargeTitles = true
        let viewModel = NotificationsViewModel()
        let vc = NotificationsViewController(viewModel: viewModel)
        nav.setViewControllers([vc], animated: false)
    }
    
}
