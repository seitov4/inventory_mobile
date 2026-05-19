//
//  QuickSaleModel.swift
//  UIKitPractice
//

import Foundation

struct SalesCartItem: Identifiable {
    let product: Product
    var quantity: Int

    var id: Int { product.id }

    var lineTotal: Double {
        product.price * Double(quantity)
    }

    var remainingStock: Int {
        max(product.quantity - quantity, 0)
    }
}

struct SalesCheckoutSummary: Identifiable, Equatable {
    let id = UUID()
    let positionsCount: Int
    let totalQuantity: Int
    let totalAmount: Double

    var totalAmountFormatted: String {
        AppCurrency.string(from: totalAmount)
    }
}

enum SalesCheckoutRoute: Identifiable, Equatable {
    case paymentSetup(SalesCheckoutSummary)

    var id: UUID {
        switch self {
        case .paymentSetup(let summary): return summary.id
        }
    }

    var summary: SalesCheckoutSummary {
        switch self {
        case .paymentSetup(let summary): return summary
        }
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
