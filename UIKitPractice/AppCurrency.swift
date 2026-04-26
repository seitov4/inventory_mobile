//
//  AppCurrency.swift
//  UIKitPractice
//

import Foundation

/// Единое форматирование сумм в тенге (KZT, символ ₸).
enum AppCurrency {
    static let code = "KZT"

    /// Общий форматтер для UI и мок-данных (не вызывать с фоновых потоков без синхронизации).
    static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.locale = Locale(identifier: "kk_KZ")
        f.maximumFractionDigits = 0
        return f
    }()

    static func string(from amount: Double) -> String {
        formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount.rounded())) ₸"
    }

    static func string(from amount: Int) -> String {
        string(from: Double(amount))
    }
}
