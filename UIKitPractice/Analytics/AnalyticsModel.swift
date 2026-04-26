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
