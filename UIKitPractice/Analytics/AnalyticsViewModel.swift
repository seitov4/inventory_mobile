//
//  AnalyticsViewModel.swift
//  UIKitPractice
//

import Foundation
import Observation

@Observable
final class AnalyticsViewModel {

    var period: AnalyticsPeriodKind = .week {
        didSet { if period != oldValue { refresh() } }
    }

    private(set) var metrics: [AnalyticsMetric] = []
    private(set) var dailySales: [AnalyticsDaySale] = []
    private(set) var categories: [AnalyticsCategoryRow] = []
    private(set) var inventoryInsight: InventoryHealthInsight = .empty

    private let productsService: ProductsServiceProtocol
    private var languageObserver: NSObjectProtocol?

    init(productsService: ProductsServiceProtocol = MockProductsService()) {
        self.productsService = productsService
        refresh()
        languageObserver = NotificationCenter.default.addObserver(
            forName: .appLanguageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    func refresh() {
        metrics = Self.makeMetrics(for: period)
        dailySales = Self.makeDailySales(for: period)
        categories = Self.makeCategories(for: period)
        loadInventoryInsight()
    }

    private func loadInventoryInsight() {
        productsService.fetchProducts(category: nil, searchQuery: nil) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let response):
                    self.inventoryInsight = Self.makeInventoryInsight(
                        products: response.products,
                        period: self.period
                    )
                case .failure:
                    self.inventoryInsight = .empty
                }
            }
        }
    }

    private static func makeMetrics(for period: AnalyticsPeriodKind) -> [AnalyticsMetric] {
        let m = period.dayCount
        let revenue = Double(m) * 42_000 + Double.random(in: 50_000...120_000)
        let orders = m * 18 + Int.random(in: -20...40)
        let avgCheck = revenue / Double(max(orders, 1))
        let conv = 3.2 + Double.random(in: -0.4...0.6)

        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.groupingSeparator = " "
        nf.maximumFractionDigits = 0

        let cf = AppCurrency.formatter

        return [
            AnalyticsMetric(
                title: L10n.tr("analytics.metric.revenue"),
                value: cf.string(from: NSNumber(value: revenue)) ?? "—",
                subtitle: L10n.tr("analytics.subtitle.period"),
                systemImage: "tengesign.circle.fill",
                tintHex: 0x1C7AF5
            ),
            AnalyticsMetric(
                title: L10n.tr("analytics.metric.orders"),
                value: nf.string(from: NSNumber(value: orders)) ?? "—",
                subtitle: L10n.tr("analytics.subtitle.pieces"),
                systemImage: "bag.fill",
                tintHex: 0x6FCF97
            ),
            AnalyticsMetric(
                title: L10n.tr("analytics.metric.avg_check"),
                value: cf.string(from: NSNumber(value: avgCheck)) ?? "—",
                subtitle: L10n.tr("analytics.subtitle.per_order"),
                systemImage: "chart.bar.doc.horizontal.fill",
                tintHex: 0xF2994A
            ),
            AnalyticsMetric(
                title: L10n.tr("analytics.metric.conversion"),
                value: String(format: "%.1f%%", conv),
                subtitle: L10n.tr("analytics.subtitle.visit_purchase"),
                systemImage: "arrow.triangle.branch",
                tintHex: 0x9B51E0
            )
        ]
    }

    private static func makeDailySales(for period: AnalyticsPeriodKind) -> [AnalyticsDaySale] {
        let labels: [String]
        let count: Int
        switch period {
        case .week:
            labels = [
                L10n.tr("analytics.week.mon"),
                L10n.tr("analytics.week.tue"),
                L10n.tr("analytics.week.wed"),
                L10n.tr("analytics.week.thu"),
                L10n.tr("analytics.week.fri"),
                L10n.tr("analytics.week.sat"),
                L10n.tr("analytics.week.sun")
            ]
            count = 7
        case .month:
            labels = (1...10).map { "\($0)" }
            count = 10
        case .quarter:
            labels = (1...13).map { L10n.format("analytics.week_number_format", $0) }
            count = 13
        }

        var result: [AnalyticsDaySale] = []
        for i in 0..<count {
            let label = labels[min(i, labels.count - 1)]
            let base = 15_000 + Double(i % 4) * 8_000
            let amount = base + Double.random(in: -4_000...12_000)
            result.append(
                AnalyticsDaySale(weekday: label, amount: max(2_000, amount), id: "\(period.rawValue)-\(i)")
            )
        }
        return result
    }

    private static func makeCategories(for period: AnalyticsPeriodKind) -> [AnalyticsCategoryRow] {
        let cf = AppCurrency.formatter

        let base = Double(period.dayCount) * 1_200
        let rows = [
            (L10n.tr("analytics.category.drinks"), 0.34, base * 1.1),
            (L10n.tr("analytics.category.snacks"), 0.26, base * 0.85),
            (L10n.tr("analytics.category.grocery"), 0.22, base * 0.7),
            (L10n.tr("analytics.category.frozen"), 0.12, base * 0.45),
            (L10n.tr("analytics.category.other"), 0.06, base * 0.25)
        ]
        return rows.map { name, share, rev in
            AnalyticsCategoryRow(
                name: name,
                share: share,
                revenueFormatted: cf.string(from: NSNumber(value: rev)) ?? "—"
            )
        }
    }

    private static func makeInventoryInsight(
        products: [Product],
        period: AnalyticsPeriodKind
    ) -> InventoryHealthInsight {
        let forecastDays = Swift.min(Swift.max(period.dayCount, 7), 14)
        let demandMultiplier = demandMultiplier(for: period)

        let allRecommendations = products.map {
            makeReorderRecommendation(
                for: $0,
                forecastDays: forecastDays,
                demandMultiplier: demandMultiplier
            )
        }

        let recommendations = allRecommendations
            .filter { $0.priority != InventoryRiskPriority.stable || $0.reorderQuantity > 0 }
            .sorted {
            if $0.priority != $1.priority {
                return $0.priority < $1.priority
            }
            return $0.daysLeft < $1.daysLeft
        }

        let riskCount = recommendations.filter { $0.priority != InventoryRiskPriority.stable }.count
        let criticalCount = recommendations.filter { $0.priority == InventoryRiskPriority.critical }.count
        let warningCount = recommendations.filter { $0.priority == InventoryRiskPriority.warning }.count
        let totalBudget = recommendations.reduce(0) { $0 + $1.estimatedCost }
        let preventedLostRevenue = recommendations.reduce(0) { partial, item in
            let shortageDays = Swift.max(0, forecastDays - item.daysLeft)
            let expectedLostUnits = Double(shortageDays) * item.dailyDemand
            let unitPrice = item.estimatedCost / Double(Swift.max(item.reorderQuantity, 1))
            return partial + expectedLostUnits * Swift.max(unitPrice, 0)
        }

        let stableRiskCount = Swift.max(0, riskCount - criticalCount - warningCount)
        let scorePenalty = criticalCount * 18 + warningCount * 9 + stableRiskCount * 4
        let score = Swift.max(28, Swift.min(100, 100 - scorePenalty))

        return InventoryHealthInsight(
            score: score,
            forecastDays: forecastDays,
            riskCount: riskCount,
            criticalCount: criticalCount,
            totalBudget: totalBudget,
            preventedLostRevenue: preventedLostRevenue,
            recommendations: recommendations
        )
    }

    private static func demandMultiplier(for period: AnalyticsPeriodKind) -> Double {
        switch period {
        case .week:
            return 1.0
        case .month:
            return 1.15
        case .quarter:
            return 1.3
        }
    }

    private static func makeReorderRecommendation(
        for product: Product,
        forecastDays: Int,
        demandMultiplier: Double
    ) -> InventoryReorderRecommendation {
        let threshold = product.lowStockThreshold ?? 8
        let deterministicBoost = Double((product.id % 4) + 1) * 0.35
        let baseDemand = Double(threshold) / 4.0 + deterministicBoost
        let dailyDemand = Swift.max(0.8, baseDemand * demandMultiplier)
        let safeQuantity = Swift.max(product.quantity, 0)
        let daysLeft = Swift.max(1, Int(ceil(Double(safeQuantity) / dailyDemand)))
        let targetStock = Int(ceil(dailyDemand * Double(forecastDays + 7)))
        let reorderQuantity = Swift.max(0, targetStock - product.quantity)
        let priority = reorderPriority(
            product: product,
            threshold: threshold,
            daysLeft: daysLeft,
            forecastDays: forecastDays
        )

        return InventoryReorderRecommendation(
            id: product.id,
            productName: product.name,
            category: product.category,
            stock: product.quantity,
            daysLeft: daysLeft,
            dailyDemand: dailyDemand,
            reorderQuantity: reorderQuantity,
            estimatedCost: Double(reorderQuantity) * product.price,
            priority: priority
        )
    }

    private static func reorderPriority(
        product: Product,
        threshold: Int,
        daysLeft: Int,
        forecastDays: Int
    ) -> InventoryRiskPriority {
        if product.quantity <= Swift.max(1, threshold / 2) || daysLeft <= 3 {
            return .critical
        }

        if product.isLowStock || daysLeft <= forecastDays {
            return .warning
        }

        return .stable
    }
}
