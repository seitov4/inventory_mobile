//
//  QuickSaleViewModel.swift
//  UIKitPractice
//

import Foundation
import Observation

@Observable
final class QuickSaleViewModel {

    private(set) var rawDigits: String = ""
    private(set) var displayAmount: String = AppCurrency.string(from: 0)
    private(set) var recent: [QuickSaleRecentRow]

    init() {
        recent = QuickSaleViewModel.mockRecent()
        updateDisplay()
    }

    func tapDigit(_ digit: Int) {
        guard digit >= 0, digit <= 9 else { return }
        guard rawDigits.count < 8 else { return }
        if rawDigits == "0" { rawDigits = "" }
        rawDigits.append(String(digit))
        updateDisplay()
    }

    func deleteLast() {
        if !rawDigits.isEmpty {
            rawDigits.removeLast()
        }
        updateDisplay()
    }

    func clear() {
        rawDigits = ""
        updateDisplay()
    }

    func stubCheckout() {
        let value = Int(rawDigits) ?? 0
        guard value > 0 else { return }
        let amount = AppCurrency.string(from: value)
        let row = QuickSaleRecentRow(
            id: UUID().uuidString,
            title: "Быстрая продажа",
            subtitle: "Только что",
            amountFormatted: amount,
            systemImage: "checkmark.circle.fill"
        )
        recent.insert(row, at: 0)
        if recent.count > 6 { recent.removeLast() }
        clear()
    }

    private func updateDisplay() {
        guard !rawDigits.isEmpty else {
            displayAmount = AppCurrency.string(from: 0)
            return
        }
        let v = Int(rawDigits) ?? 0
        displayAmount = AppCurrency.string(from: v)
    }

    private static func mockRecent() -> [QuickSaleRecentRow] {
        [
            QuickSaleRecentRow(
                id: "r1",
                title: "Кофе и круассан",
                subtitle: "12:04 · Касса 1",
                amountFormatted: AppCurrency.string(from: 420),
                systemImage: "cup.and.saucer.fill"
            ),
            QuickSaleRecentRow(
                id: "r2",
                title: "Вода 0,5 × 3",
                subtitle: "11:51 · Касса 2",
                amountFormatted: AppCurrency.string(from: 195),
                systemImage: "drop.fill"
            ),
            QuickSaleRecentRow(
                id: "r3",
                title: "Скидка по карте",
                subtitle: "11:12 · Касса 1",
                amountFormatted: AppCurrency.string(from: 1280),
                systemImage: "creditcard.fill"
            )
        ]
    }
}
