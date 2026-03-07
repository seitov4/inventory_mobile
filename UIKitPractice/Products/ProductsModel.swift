//
//  ProductsModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 10.12.2025.
//

import Foundation

struct Product: Decodable, Identifiable {
    let id: Int
    let name: String
    let barcode: String?
    let price: Double
    let quantity: Int
    let category: String
    let lowStockThreshold: Int?
    
    var isLowStock: Bool {
        guard let threshold = lowStockThreshold else { return false }
        return quantity <= threshold
    }
    
    var formattedPrice: String {
        return String(format: "$%.0f", price)
    }
    
    var displaySubtitle: String {
        var parts: [String] = []
        if let barcode = barcode, !barcode.isEmpty {
            parts.append(barcode)
        }
        parts.append(formattedPrice)
        return parts.joined(separator: " • ")
    }
}

// MARK: - ProductStats

struct ProductStats: Decodable {
    let totalProducts: Int
    let lowStockCount: Int
    let totalValue: Double
    
    var formattedValue: String {
        return String(format: "$%.0f", totalValue)
    }
}

// MARK: - ProductsResponse

struct ProductsResponse: Decodable {
    let products: [Product]
    let stats: ProductStats?
    let categories: [String]
}

// MARK: - Category

struct Category {
    let name: String
    let displayName: String
    
    static let all = Category(name: "all", displayName: "All")
    
    var isAll: Bool {
        return name == "all"
    }
}
