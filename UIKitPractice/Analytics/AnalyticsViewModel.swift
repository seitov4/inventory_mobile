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
    private var languageObserver: NSObjectProtocol?

    init() {
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
}
