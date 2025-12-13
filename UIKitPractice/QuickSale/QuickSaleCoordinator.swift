//
//  QuickSaleCoordinator.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 10.12.2025.
//

import Foundation
import UIKit

final class QuickSaleCoordinator: Coordinator {

    var childCoordinators: [Coordinator] = []
    private let nav: UINavigationController

    init(navigationController: UINavigationController) {
        self.nav = navigationController
    }

    func start() {
        let vc = QuickSaleViewController()
        nav.setViewControllers([vc], animated: false)
    }
}
