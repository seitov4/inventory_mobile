//
//  MockProductsService.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 25.01.2026.
//

import Foundation

final class MockProductsService {
    
    func fetchProducts(
        category: String? = nil,
        searchQuery: String? = nil,
        completion: @escaping (Result<ProductsResponse, Error>) -> Void
    ) {
        // Имитация задержки сети
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let mockProducts = self.generateMockProducts()
            let filteredProducts = self.filterProducts(mockProducts, category: category, searchQuery: searchQuery)
            let stats = self.calculateStats(from: filteredProducts)
            let categories = Array(Set(mockProducts.map { $0.category }))
            
            let response = ProductsResponse(
                products: filteredProducts,
                stats: stats,
                categories: categories
            )
            
            completion(.success(response))
        }
    }
    
    private func generateMockProducts() -> [Product] {
        return [
            Product(id: 1, name: "Молоко 3.2%", barcode: "4600123456789", price: 89, quantity: 45, category: "Молочные", lowStockThreshold: 10),
            Product(id: 2, name: "Сыр Российский", barcode: "4600123456790", price: 459, quantity: 8, category: "Молочные", lowStockThreshold: 10),
            Product(id: 3, name: "Хлеб белый", barcode: "4600123456791", price: 45, quantity: 12, category: "Хлеб", lowStockThreshold: 15),
            Product(id: 4, name: "Колбаса Докторская", barcode: "4600123456792", price: 389, quantity: 5, category: "Мясные", lowStockThreshold: 10),
            Product(id: 5, name: "Вода минеральная", barcode: "4600123456793", price: 35, quantity: 120, category: "Напитки", lowStockThreshold: 20),
            Product(id: 6, name: "Кофе растворимый", barcode: "4600123456794", price: 299, quantity: 3, category: "Напитки", lowStockThreshold: 10)
        ]
    }
    
    private func filterProducts(_ products: [Product], category: String?, searchQuery: String?) -> [Product] {
        var filtered = products
        
        if let category = category, category != "all" {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let search = searchQuery, !search.isEmpty {
            let query = search.lowercased()
            filtered = filtered.filter {
                $0.name.lowercased().contains(query) ||
                $0.category.lowercased().contains(query) ||
                ($0.barcode?.lowercased().contains(query) ?? false)
            }
        }
        
        return filtered
    }
    
    private func calculateStats(from products: [Product]) -> ProductStats {
        let totalProducts = products.count
        let lowStockCount = products.filter { $0.isLowStock }.count
        let totalValue = products.reduce(0.0) { $0 + ($1.price * Double($1.quantity)) }
        
        return ProductStats(
            totalProducts: totalProducts,
            lowStockCount: lowStockCount,
            totalValue: totalValue
        )
    }
}
