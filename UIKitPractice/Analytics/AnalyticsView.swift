//
//  AnalyticsView.swift
//  UIKitPractice
//

import Charts
import Observation
import SwiftUI

struct AnalyticsScreen: View {
    @Bindable var viewModel: AnalyticsViewModel
    let onOpenAIChat: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isBannerVisible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                analyticsHeader

                aiPromoBanner
                    .opacity(isBannerVisible ? 1 : 0)
                    .offset(y: isBannerVisible ? 0 : 8)

                Picker("Период", selection: $viewModel.period) {
                    ForEach(AnalyticsPeriodKind.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)

                metricsRow

                chartCard

                categoriesSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                isBannerVisible = true
            }
        }
    }

    private var analyticsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Главная")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Аналитика")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button(action: onOpenAIChat) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                    Text("AI чат")
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

                    Text("Повысьте продажи с AI-\nпомощником")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text("Анализ конкурентов, прогноз спроса и идеи роста за секунды")
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
            Text("Динамика продаж")
                .font(.headline)
            Text("Сумма по дням (мок-данные)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(viewModel.dailySales) { row in
                BarMark(
                    x: .value("День", row.weekday),
                    y: .value("Сумма", row.amount)
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
            Text("Категории")
                .font(.headline)
            Text("Доля выручки")
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
