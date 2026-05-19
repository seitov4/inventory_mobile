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
    var checkoutRoute: SalesCheckoutRoute?

    private let productsService: ProductsServiceProtocol
    private var productsByBarcode: [String: Product] = [:]
    private var lastScanByBarcode: [String: Date] = [:]
    private let debounceInterval: TimeInterval = 1.5
    private let successScanSoundID: SystemSoundID = 1057
    private let failedScanSoundID: SystemSoundID = 1053
    private var languageObserver: NSObjectProtocol?

    var hasItems: Bool {
        !cartItems.isEmpty
    }

    var positionsCount: Int {
        cartItems.count
    }

    var totalQuantity: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    var totalAmount: Double {
        cartItems.reduce(0) { $0 + $1.lineTotal }
    }

    var totalAmountFormatted: String {
        AppCurrency.string(from: totalAmount)
    }

    var testProducts: [Product] {
        productsByBarcode.values.sorted { $0.id < $1.id }
    }

    init(productsService: ProductsServiceProtocol = MockProductsService()) {
        self.productsService = productsService
        seedLocalCatalog()
        refreshCatalog()
        languageObserver = NotificationCenter.default.addObserver(
            forName: .appLanguageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadLocalizedCatalog()
        }
    }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    func processBarcode(_ rawBarcode: String) {
        let barcode = rawBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !barcode.isEmpty else { return }

        if shouldDebounce(barcode) {
            return
        }

        guard let product = productsByBarcode[barcode] else {
            playFailedScanSound()
            showToast(L10n.format("sales.product_not_found_format", barcode), style: .destructive)
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
        showToast(L10n.tr("sales.mock_receipt_ready"), style: .success)
    }

    func hardwareScannerActivated() {
        showToast(L10n.tr("sales.hardware_ready"), style: .success)
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
        checkoutRoute = .paymentSetup(makeCheckoutSummary())
    }

    func connectPaymentInfrastructureForDemo() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showToast(L10n.tr("sales.payment_setup_connected_toast"), style: .success)
    }

    func finishSaleAfterPaymentSetup() {
        guard hasItems else {
            checkoutRoute = nil
            return
        }
        checkoutRoute = nil
        finalizeSale()
    }

    func dismissCheckout() {
        checkoutRoute = nil
    }

    private func makeCheckoutSummary() -> SalesCheckoutSummary {
        SalesCheckoutSummary(
            positionsCount: positionsCount,
            totalQuantity: totalQuantity,
            totalAmount: totalAmount
        )
    }

    private func finalizeSale() {
        clearCart()
        showToast(L10n.tr("sales.completed"), style: .success)
    }

    private func add(_ product: Product, bypassDebounce: Bool = false, source: AddSource = .manual) {
        if product.quantity <= 0 {
            if source.playsScanSound { playFailedScanSound() }
            showToast(L10n.tr("sales.out_of_stock"), style: .warning)
            return
        }

        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            guard cartItems[index].quantity < product.quantity else {
                if source.playsScanSound { playFailedScanSound() }
                showToast(L10n.tr("sales.stock_limit"), style: .warning)
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
            Product(id: 1, name: L10n.tr("product.mock.milk"), barcode: "4600123456789", price: 89, quantity: 45, category: L10n.tr("product.category.dairy"), lowStockThreshold: 10),
            Product(id: 2, name: L10n.tr("product.mock.cheese"), barcode: "4600123456790", price: 459, quantity: 8, category: L10n.tr("product.category.dairy"), lowStockThreshold: 10),
            Product(id: 3, name: L10n.tr("product.mock.bread"), barcode: "4600123456791", price: 45, quantity: 12, category: L10n.tr("product.category.bread"), lowStockThreshold: 15),
            Product(id: 4, name: L10n.tr("product.mock.sausage"), barcode: "4600123456792", price: 389, quantity: 5, category: L10n.tr("product.category.meat"), lowStockThreshold: 10),
            Product(id: 5, name: L10n.tr("product.mock.water"), barcode: "4600123456793", price: 35, quantity: 120, category: L10n.tr("product.category.drinks"), lowStockThreshold: 20),
            Product(id: 6, name: L10n.tr("product.mock.coffee"), barcode: "4600123456794", price: 299, quantity: 3, category: L10n.tr("product.category.drinks"), lowStockThreshold: 10)
        ]

        productsByBarcode = Dictionary(
            uniqueKeysWithValues: products.compactMap { product in
                guard let barcode = product.barcode else { return nil }
                return (barcode, product)
            }
        )
    }

    private func reloadLocalizedCatalog() {
        let quantitiesByID = Dictionary(uniqueKeysWithValues: cartItems.map { ($0.product.id, $0.quantity) })
        seedLocalCatalog()
        refreshCatalog()
        cartItems = cartItems.compactMap { item in
            guard let barcode = item.product.barcode,
                  let localizedProduct = productsByBarcode[barcode] else {
                return item
            }
            return SalesCartItem(product: localizedProduct, quantity: quantitiesByID[item.product.id] ?? item.quantity)
        }
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
