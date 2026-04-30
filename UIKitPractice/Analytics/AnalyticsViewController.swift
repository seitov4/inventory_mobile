//
//  AnalyticsViewController.swift
//  UIKitPractice
//

import SwiftUI
import UIKit

final class AnalyticsViewController: UIViewController {

    private let viewModel: AnalyticsViewModel
    private var hostingController: UIHostingController<AnalyticsScreen>?

    init(viewModel: AnalyticsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = ""
        navigationItem.largeTitleDisplayMode = .never

        let root = AnalyticsScreen(viewModel: viewModel) { [weak self] in
            self?.openAIChat()
        }
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
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

    private func openAIChat() {
        let chat = AIChatScreen(viewModel: AIChatViewModel(service: MockAIChatService()))
        let vc = UIHostingController(rootView: chat)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
