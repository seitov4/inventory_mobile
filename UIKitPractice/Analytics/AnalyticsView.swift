//
//  AnalyticsView.swift
//  UIKitPractice
//

import Charts
import Observation
import SwiftUI
import UIKit

struct AnalyticsScreen: View {
    @Bindable var viewModel: AnalyticsViewModel
    let onOpenAIChat: () -> Void
    let onOpenReports: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isBannerVisible = false
    @State private var isReorderPlanPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                analyticsHeader

                aiPromoBanner
                    .opacity(isBannerVisible ? 1 : 0)
                    .offset(y: isBannerVisible ? 0 : 8)

                reportsEntryCard
                    .opacity(isBannerVisible ? 1 : 0)
                    .offset(y: isBannerVisible ? 0 : 8)

                Picker(L10n.tr("analytics.period"), selection: $viewModel.period) {
                    ForEach(AnalyticsPeriodKind.allCases) { p in
                        Text(p.title).tag(p)
                    }
                }
                .pickerStyle(.segmented)

                metricsRow

                inventoryForecastCard

                chartCard

                categoriesSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .appLocalized()
        .sheet(isPresented: $isReorderPlanPresented) {
            InventoryReorderPlanSheet(insight: viewModel.inventoryInsight)
                .appLocalized()
        }
        .onAppear {
            AppAnalytics.shared.trackScreen("analytics")
            withAnimation(.easeOut(duration: 0.35)) {
                isBannerVisible = true
            }
        }
    }

    private var inventoryForecastCard: some View {
        let insight = viewModel.inventoryInsight

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(.systemBlue).opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color(.systemBlue))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.tr("analytics.stock.title"))
                        .font(.headline)
                    Text(L10n.tr("analytics.stock.subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Text("AI")
                    .font(.caption.bold())
                    .foregroundStyle(Color(.systemBlue))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color(.systemBlue).opacity(0.12), in: Capsule())
            }

            HStack(spacing: 16) {
                Gauge(value: Double(insight.score), in: 0...100) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(insight.score)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(healthTint(for: insight.score))
                .frame(width: 92, height: 92)

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.tr("analytics.stock.health_score"))
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.format("analytics.stock.forecast_days_format", insight.forecastDays))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        insightPill(
                            title: L10n.tr("analytics.stock.risk_items"),
                            value: "\(insight.riskCount)",
                            tint: insight.criticalCount > 0 ? Color(.systemRed) : Color(.systemOrange)
                        )
                        insightPill(
                            title: L10n.tr("analytics.stock.budget"),
                            value: insight.totalBudgetFormatted,
                            tint: Color(.systemBlue)
                        )
                    }
                }
            }
            .padding(14)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(L10n.tr("analytics.stock.recommendations"))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(L10n.tr("analytics.stock.live_badge"))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(.systemGreen))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGreen).opacity(0.12), in: Capsule())
                }

                if insight.recommendations.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color(.systemGreen))
                        Text(L10n.tr("analytics.stock.all_good"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(insight.recommendations.prefix(3)) { item in
                        InventoryRecommendationMiniRow(item: item)
                    }
                }
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                isReorderPlanPresented = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text(L10n.tr("analytics.stock.open_plan"))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color(.systemBlue), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 12, y: 5)
        }
    }

    private func insightPill(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func healthTint(for score: Int) -> Color {
        if score >= 80 { return Color(.systemGreen) }
        if score >= 55 { return Color(.systemOrange) }
        return Color(.systemRed)
    }

    private var analyticsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.tr("Главная"))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(L10n.tr("Аналитика"))
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button(action: onOpenAIChat) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                    Text(L10n.tr("AI чат"))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(AnalyticsAIPalette.primaryGradient)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
    }

    private var aiPromoBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AnalyticsAIPalette.primaryGradient)
                .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 12, y: 6)

            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .offset(x: 150, y: -56)

            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
                .offset(x: 138, y: 52)

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.14))
                    .frame(width: 84, height: 84)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    )

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 6, height: 6)
                        Text("InventiX · AI")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.white.opacity(0.14))
                    )

                    Text(L10n.tr("analytics.ai_promo_title"))
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text(L10n.tr("analytics.ai_promo_subtitle"))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Button(action: onOpenAIChat) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 56, height: 56)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(uiColor: UIColor(hex: 0x6E47E8)))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .frame(height: 155)
    }

    private var reportsEntryCard: some View {
        Button(action: onOpenReports) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(ReportsBannerPalette.gradient)
                    .shadow(color: ReportsBannerPalette.shadow.opacity(colorScheme == .dark ? 0.22 : 0.28), radius: 16, y: 8)

                Circle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 120, height: 120)
                    .offset(x: 148, y: -54)

                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.28))
                    .offset(x: 146, y: 50)

                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.18))
                        .frame(width: 64, height: 64)
                        .overlay {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 29, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(.white.opacity(0.9))
                                .frame(width: 6, height: 6)
                            Text(L10n.tr("reports.banner.badge"))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.96))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.14), in: Capsule())

                        Text(L10n.tr("reports.owner_title"))
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(L10n.tr("reports.analytics_banner_subtitle"))
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(2)
                    }
                    .layoutPriority(1)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white.opacity(0.88))
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.13), in: Circle())
                }
                .padding(18)
            }
            .frame(height: 128)
        }
        .buttonStyle(ReportsBannerButtonStyle())
    }

    private var metricsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.metrics) { m in
                    metricCard(m)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func metricCard(_ m: AnalyticsMetric) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: m.systemImage)
                .font(.title3)
                .foregroundStyle(Color(uiColor: UIColor(hex: m.tintHex)))
            Text(m.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(m.value)
                .font(.headline)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(m.subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(width: 132, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 8, y: 3)
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Динамика продаж"))
                .font(.headline)
            Text(L10n.tr("analytics.chart.subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(viewModel.dailySales) { row in
                BarMark(
                    x: .value(L10n.tr("analytics.chart.day"), row.weekday),
                    y: .value(L10n.tr("analytics.chart.amount"), row.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(uiColor: UIColor(hex: 0x1C7AF5)),
                            Color(uiColor: UIColor(hex: 0x1C7AF5)).opacity(0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(6)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { v in
                    AxisGridLine()
                    AxisValueLabel {
                        if let n = v.as(Double.self) {
                            Text(shortCurrency(n))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 10, y: 4)
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.tr("Категории"))
                .font(.headline)
            Text(L10n.tr("analytics.categories.subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                ForEach(viewModel.categories) { row in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(row.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(row.revenueFormatted)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.tertiarySystemFill))
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(uiColor: UIColor(hex: 0x1C7AF5)),
                                                Color(uiColor: UIColor(hex: 0x6FCF97))
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(8, geo.size.width * row.share))
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 10, y: 4)
        }
    }

    private func shortCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }
}

private struct InventoryRecommendationMiniRow: View {
    let item: InventoryReorderRecommendation

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(priorityTint.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: item.priority.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(priorityTint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(L10n.format("analytics.stock.days_left_format", item.daysLeft))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(L10n.format("analytics.stock.order_qty_format", item.reorderQuantity))
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                Text(item.priority.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(priorityTint)
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var priorityTint: Color {
        switch item.priority {
        case .critical: return Color(.systemRed)
        case .warning: return Color(.systemOrange)
        case .stable: return Color(.systemGreen)
        }
    }
}

private struct InventoryReorderPlanSheet: View {
    let insight: InventoryHealthInsight

    @Environment(\.dismiss) private var dismiss
    @State private var isDraftGenerated = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    summaryGrid

                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("analytics.stock.plan_items"))
                            .font(.headline)

                        if insight.recommendations.isEmpty {
                            Text(L10n.tr("analytics.stock.plan_empty"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        } else {
                            ForEach(insight.recommendations) { item in
                                planRow(item)
                            }
                        }
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            isDraftGenerated = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: isDraftGenerated ? "checkmark.circle.fill" : "wand.and.stars")
                            Text(isDraftGenerated ? L10n.tr("analytics.stock.draft_ready") : L10n.tr("analytics.stock.generate_draft"))
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(Color(.systemBlue), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.tr("analytics.stock.plan_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.tr("common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(.systemBlue))
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.tr("analytics.stock.plan_header"))
                        .font(.headline)
                    Text(L10n.tr("analytics.stock.plan_subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            summaryCard(L10n.tr("analytics.stock.health_score"), "\(insight.score)", "gauge.with.dots.needle.67percent")
            summaryCard(L10n.tr("analytics.stock.risk_items"), "\(insight.riskCount)", "exclamationmark.triangle.fill")
            summaryCard(L10n.tr("analytics.stock.budget"), insight.totalBudgetFormatted, "creditcard.fill")
            summaryCard(L10n.tr("analytics.stock.saved_revenue"), insight.preventedLostRevenueFormatted, "chart.line.uptrend.xyaxis")
        }
    }

    private func summaryCard(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color(.systemBlue))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func planRow(_ item: InventoryReorderRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.productName)
                        .font(.subheadline.weight(.semibold))
                    Text(item.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(item.priority.title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(priorityTint(for: item.priority))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityTint(for: item.priority).opacity(0.12), in: Capsule())
            }

            HStack {
                planFact(title: L10n.tr("analytics.stock.current_stock"), value: "\(item.stock)")
                planFact(title: L10n.tr("analytics.stock.days_left"), value: "\(item.daysLeft)")
                planFact(title: L10n.tr("analytics.stock.reorder"), value: "\(item.reorderQuantity)")
                planFact(title: L10n.tr("analytics.stock.cost"), value: item.estimatedCostFormatted)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func planFact(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func priorityTint(for priority: InventoryRiskPriority) -> Color {
        switch priority {
        case .critical: return Color(.systemRed)
        case .warning: return Color(.systemOrange)
        case .stable: return Color(.systemGreen)
        }
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

enum AnalyticsAIPalette {
    static let primaryGradient = LinearGradient(
        colors: [
            Color(uiColor: UIColor(hex: 0x6E47E8)),
            Color(uiColor: UIColor(hex: 0x5A6BFF))
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

enum ReportsBannerPalette {
    static let gradient = LinearGradient(
        colors: [
            Color(.systemTeal),
            Color(.systemGreen),
            Color(.systemBlue).opacity(0.82)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let shadow = Color(.systemTeal)
}

struct ReportsBannerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
