//
//  DashboardViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import Foundation

final class DashboardViewModel{
    
    private(set) var todaySales: Double = 0.0
    
    var onUpdate: (() -> Void)?
    
    func loadData() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.todaySales = 1233.32
            DispatchQueue.main.async{
                self.onUpdate?()
            }
        }
    }
}
