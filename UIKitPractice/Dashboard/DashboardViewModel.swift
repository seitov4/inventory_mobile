//
//  DashboardViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import Foundation

final class DashboardViewModel{
    
    private(set) var todaySales: Double = 0.0
    private let salesService: SalesService
    
    var onUpdate: (() -> Void)?
    var onError: ((String) -> Void)?

    init(salesService: SalesService = .shared) {
        self.salesService = salesService
    }
    
    func loadData() {
        salesService.fetchDailySales { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let payload):
                    self.todaySales = payload.revenue
                    self.onUpdate?()
                case .failure(let error):
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }
}
