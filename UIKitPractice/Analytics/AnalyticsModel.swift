//
//  AnalyticsModel.swift
//  UIKitPractice
//

import Foundation

enum AnalyticsPeriodKind: String, CaseIterable, Identifiable {
    case week = "7 дней"
    case month = "30 дней"
    case quarter = "90 дней"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return L10n.tr("analytics.period.week")
        case .month: return L10n.tr("analytics.period.month")
        case .quarter: return L10n.tr("analytics.period.quarter")
        }
    }

    var dayCount: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }
}

struct AnalyticsMetric: Identifiable, Equatable {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let tintHex: UInt32

    var id: String { title }
}

struct AnalyticsDaySale: Identifiable, Equatable {
    let weekday: String
    let amount: Double
    let id: String
}

struct AnalyticsCategoryRow: Identifiable, Equatable {
    let name: String
    let share: Double
    let revenueFormatted: String

    var id: String { name }
}

enum InventoryRiskPriority: Int, Comparable, Equatable {
    case critical = 0
    case warning = 1
    case stable = 2

    static func < (lhs: InventoryRiskPriority, rhs: InventoryRiskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .critical: return L10n.tr("analytics.stock.priority.critical")
        case .warning: return L10n.tr("analytics.stock.priority.warning")
        case .stable: return L10n.tr("analytics.stock.priority.stable")
        }
    }

    var systemImage: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "clock.badge.exclamationmark.fill"
        case .stable: return "checkmark.seal.fill"
        }
    }
}

struct InventoryReorderRecommendation: Identifiable, Equatable {
    let id: Int
    let productName: String
    let category: String
    let stock: Int
    let daysLeft: Int
    let dailyDemand: Double
    let reorderQuantity: Int
    let estimatedCost: Double
    let priority: InventoryRiskPriority

    var estimatedCostFormatted: String {
        AppCurrency.string(from: estimatedCost)
    }

    var dailyDemandText: String {
        String(format: "%.1f", dailyDemand)
    }
}

struct InventoryHealthInsight: Equatable {
    let score: Int
    let forecastDays: Int
    let riskCount: Int
    let criticalCount: Int
    let totalBudget: Double
    let preventedLostRevenue: Double
    let recommendations: [InventoryReorderRecommendation]

    static let empty = InventoryHealthInsight(
        score: 100,
        forecastDays: 7,
        riskCount: 0,
        criticalCount: 0,
        totalBudget: 0,
        preventedLostRevenue: 0,
        recommendations: []
    )

    var totalBudgetFormatted: String {
        AppCurrency.string(from: totalBudget)
    }

    var preventedLostRevenueFormatted: String {
        AppCurrency.string(from: preventedLostRevenue)
    }
}
