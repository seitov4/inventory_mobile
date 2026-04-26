//
//  QuickSaleModel.swift
//  UIKitPractice
//

import Foundation

struct QuickSaleRecentRow: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let amountFormatted: String
    let systemImage: String
}
