//
//  WelcomeViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit

final class WelcomeViewController: UIViewController {
    private let rootView: WelcomeView
    private let viewModel: WelcomeViewModel
    
    init(viewModel: WelcomeViewModel) {
        self.viewModel = viewModel
        self.rootView = WelcomeView()
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder: ) has not been implemented") }
    
    override func loadView() {
        view = rootView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    private func setupBindings() {
        rootView.loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
    }
    
    @objc private func loginTapped() {
        viewModel.loginTapped()
        print ("VC loginTapped")
    }
}
