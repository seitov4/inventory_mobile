//
//  QuickSaleViewModel.swift
//  UIKitPractice
//

import Foundation
import Observation
import UIKit
import AudioToolbox

@Observable
final class QuickSaleViewModel {

    private(set) var cartItems: [SalesCartItem] = []
    var toast: SalesToast?

    private let productsService: ProductsServiceProtocol
    private var productsByBarcode: [String: Product] = [:]
    private var lastScanByBarcode: [String: Date] = [:]
    private let debounceInterval: TimeInterval = 1.5
    private let successScanSoundID: SystemSoundID = 1057
    private let failedScanSoundID: SystemSoundID = 1053

    var hasItems: Bool {
        !cartItems.isEmpty
    }

    var positionsCount: Int {
        cartItems.count
    }

    var totalQuantity: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    var testProducts: [Product] {
        productsByBarcode.values.sorted { $0.id < $1.id }
    }

    init(productsService: ProductsServiceProtocol = MockProductsService()) {
        self.productsService = productsService
        seedLocalCatalog()
        refreshCatalog()
    }

    func processBarcode(_ rawBarcode: String) {
        let barcode = rawBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !barcode.isEmpty else { return }

        if shouldDebounce(barcode) {
            return
        }

        guard let product = productsByBarcode[barcode] else {
            playSuccessScanSound()
            showToast("Товар не найден: \(barcode)", style: .destructive)
            return
        }

        add(product, source: .barcodeScan)
    }

    func mockScan(_ product: Product) {
        guard let barcode = product.barcode else { return }
        processBarcode(barcode)
    }

    func fillMockReceipt() {
        clearCart()
        for barcode in ["4600123456789", "4600123456791", "4600123456793"] {
            if let product = productsByBarcode[barcode] {
                add(product, bypassDebounce: true, source: .mock)
            }
        }
        showToast("Моковый чек готов", style: .success)
    }

    func hardwareScannerActivated() {
        showToast("Проводной сканер готов", style: .success)
    }

    func increment(_ item: SalesCartItem) {
        add(item.product, bypassDebounce: true, source: .manual)
    }

    func decrement(_ item: SalesCartItem) {
        guard let index = cartItems.firstIndex(where: { $0.id == item.id }) else { return }
        if cartItems[index].quantity > 1 {
            cartItems[index].quantity -= 1
        } else {
            cartItems.remove(at: index)
        }
    }

    func remove(_ item: SalesCartItem) {
        cartItems.removeAll { $0.id == item.id }
    }

    func clearCart() {
        cartItems.removeAll()
    }

    func completeSale() {
        guard hasItems else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        clearCart()
        showToast("Продажа завершена", style: .success)
    }

    private func add(_ product: Product, bypassDebounce: Bool = false, source: AddSource = .manual) {
        if product.quantity <= 0 {
            if source.playsScanSound { playSuccessScanSound() }
            showToast("Нет в наличии", style: .warning)
            return
        }

        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            guard cartItems[index].quantity < product.quantity else {
                if source.playsScanSound { playSuccessScanSound() }
                showToast("Достигнут остаток", style: .warning)
                return
            }
            cartItems[index].quantity += 1
            let item = cartItems.remove(at: index)
            cartItems.insert(item, at: 0)
        } else {
            cartItems.insert(SalesCartItem(product: product, quantity: 1), at: 0)
        }

        if !bypassDebounce, let barcode = product.barcode {
            lastScanByBarcode[barcode] = Date()
        }

        if source.playsScanSound {
            playSuccessScanSound()
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private enum AddSource {
        case barcodeScan
        case mock
        case manual

        var playsScanSound: Bool {
            switch self {
            case .barcodeScan, .mock: return true
            case .manual: return false
            }
        }
    }

    private func playSuccessScanSound() {
        AudioServicesPlaySystemSound(successScanSoundID)
    }

    private func playFailedScanSound() {
        AudioServicesPlaySystemSound(failedScanSoundID)
    }

    private func shouldDebounce(_ barcode: String) -> Bool {
        if let lastScan = lastScanByBarcode[barcode],
           Date().timeIntervalSince(lastScan) < debounceInterval {
            return true
        }
        lastScanByBarcode[barcode] = Date()
        return false
    }

    private func refreshCatalog() {
        // TODO: Connect to API
        productsService.fetchProducts(category: nil, searchQuery: nil) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                if case .success(let response) = result {
                    self.productsByBarcode = Dictionary(
                        uniqueKeysWithValues: response.products.compactMap { product in
                            guard let barcode = product.barcode, !barcode.isEmpty else { return nil }
                            return (barcode, product)
                        }
                    )
                }
            }
        }
    }

    private func seedLocalCatalog() {
        let products = [
            Product(id: 1, name: "Молоко 3.2%", barcode: "4600123456789", price: 89, quantity: 45, category: "Молочные", lowStockThreshold: 10),
            Product(id: 2, name: "Сыр Российский", barcode: "4600123456790", price: 459, quantity: 8, category: "Молочные", lowStockThreshold: 10),
            Product(id: 3, name: "Хлеб белый", barcode: "4600123456791", price: 45, quantity: 12, category: "Хлеб", lowStockThreshold: 15),
            Product(id: 4, name: "Колбаса Докторская", barcode: "4600123456792", price: 389, quantity: 5, category: "Мясные", lowStockThreshold: 10),
            Product(id: 5, name: "Вода минеральная", barcode: "4600123456793", price: 35, quantity: 120, category: "Напитки", lowStockThreshold: 20),
            Product(id: 6, name: "Кофе растворимый", barcode: "4600123456794", price: 299, quantity: 3, category: "Напитки", lowStockThreshold: 10)
        ]

        productsByBarcode = Dictionary(
            uniqueKeysWithValues: products.compactMap { product in
                guard let barcode = product.barcode else { return nil }
                return (barcode, product)
            }
        )
    }

    private func showToast(_ message: String, style: SalesToast.Style) {
        let toast = SalesToast(message: message, style: style)
        self.toast = toast

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard self?.toast == toast else { return }
            self?.toast = nil
        }
    }
}
