//
//  DashboardViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit

final class DashboardViewController: UIViewController {
    
    private let rootView = DashboardView()
    private let viewModel: DashboardViewModel
    
    init(viewModel: DashboardViewModel){
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}
        
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        viewModel.loadData()
    }
    
    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] in
            guard let self = self else { return }
            self.rootView.summaryLabel.text = "Продаж за сегодня: \(AppCurrency.string(from: self.viewModel.todaySales))"
        }
    }
}
