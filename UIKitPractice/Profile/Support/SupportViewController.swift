//
//  SupportViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit

final class SupportViewController: UIViewController {

    private let contentView = SupportView()

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Поддержка"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
