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
        // TODO: Connect to API
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

    func fetchProduct(
        barcode: String,
        completion: @escaping (Result<Product, Error>) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let trimmedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
            if let product = self.generateMockProducts().first(where: { $0.barcode == trimmedBarcode }) {
                completion(.success(product))
            } else {
                completion(.failure(AppError.notFound))
            }
        }
    }
    
    private func generateMockProducts() -> [Product] {
        return [
            Product(id: 1, name: L10n.tr("product.mock.milk"), barcode: "4600123456789", price: 89, quantity: 45, category: L10n.tr("product.category.dairy"), lowStockThreshold: 10),
            Product(id: 2, name: L10n.tr("product.mock.cheese"), barcode: "4600123456790", price: 459, quantity: 8, category: L10n.tr("product.category.dairy"), lowStockThreshold: 10),
            Product(id: 3, name: L10n.tr("product.mock.bread"), barcode: "4600123456791", price: 45, quantity: 12, category: L10n.tr("product.category.bread"), lowStockThreshold: 15),
            Product(id: 4, name: L10n.tr("product.mock.sausage"), barcode: "4600123456792", price: 389, quantity: 5, category: L10n.tr("product.category.meat"), lowStockThreshold: 10),
            Product(id: 5, name: L10n.tr("product.mock.water"), barcode: "4600123456793", price: 35, quantity: 120, category: L10n.tr("product.category.drinks"), lowStockThreshold: 20),
            Product(id: 6, name: L10n.tr("product.mock.coffee"), barcode: "4600123456794", price: 299, quantity: 3, category: L10n.tr("product.category.drinks"), lowStockThreshold: 10)
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
