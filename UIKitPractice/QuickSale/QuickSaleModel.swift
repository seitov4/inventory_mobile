//
//  QuickSaleModel.swift
//  UIKitPractice
//

import Foundation

struct SalesCartItem: Identifiable {
    let product: Product
    var quantity: Int

    var id: Int { product.id }

    var remainingStock: Int {
        max(product.quantity - quantity, 0)
    }
}

struct SalesToast: Identifiable, Equatable {
    enum Style {
        case success
        case warning
        case destructive
    }

    let id = UUID()
    let message: String
    let style: Style
}
