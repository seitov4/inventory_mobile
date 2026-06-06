//
//  ProductsViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 10.12.2025.
//

import UIKit
import SwiftUI

final class ProductsViewController: UIViewController {
    private let productsViewModel: ProductsViewModel
    private var hostingController: UIHostingController<ProductsInventoryScreen>?

    init(viewModel: ProductsViewModel = ProductsViewModel(productsService: ProductsService())) {
        self.productsViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = L10n.tr("Товары")
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        let state = ProductsInventoryState(viewModel: productsViewModel)
        let root = ProductsInventoryScreen(state: state)
        let host = UIHostingController(rootView: root)
        hostingController = host

        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
    }
}
