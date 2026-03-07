//
//  DashboardCoordinator.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit

final class DashboardCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vm = DashboardViewModel()
        let vc = DashboardViewController(viewModel: vm)
        vc.title = "Дашборд"
        navigationController.pushViewController(vc, animated: true)
    }
}
