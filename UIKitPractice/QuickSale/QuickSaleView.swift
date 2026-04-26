//
//  QuickSaleView.swift
//  UIKitPractice
//

import Observation
import SwiftUI

struct QuickSaleScreen: View {
    @Bindable var viewModel: QuickSaleViewModel
    @Environment(\.colorScheme) private var colorScheme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                amountCard

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(1...9, id: \.self) { n in
                        digitButton("\(n)") {
                            viewModel.tapDigit(n)
                        }
                    }
                    digitButton("⌫", role: .destructive) {
                        viewModel.deleteLast()
                    }
                    digitButton("0") {
                        viewModel.tapDigit(0)
                    }
                    digitButton("C", role: .muted) {
                        viewModel.clear()
                    }
                }
                .padding(.horizontal, 4)

                VStack(spacing: 12) {
                    Button {
                        viewModel.stubCheckout()
                    } label: {
                        Label("Пробить чек", systemImage: "printer.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(uiColor: UIColor(hex: 0x1C7AF5)))

                    Button {
                        // UI-only
                    } label: {
                        Label("Сканировать штрихкод", systemImage: "barcode.viewfinder")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                }

                recentSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Сумма к оплате")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(viewModel.displayAmount)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 12, y: 4)
        }
    }

    private func digitButton(
        _ title: String,
        role: KeypadRole = .normal,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(role.background)
                }
                .foregroundStyle(role.foreground)
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Недавние операции")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recent.enumerated()), id: \.element.id) { index, row in
                    recentRow(row)
                    if index < viewModel.recent.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 8, y: 2)
            }
        }
    }

    private func recentRow(_ row: QuickSaleRecentRow) -> some View {
        HStack(spacing: 14) {
            Image(systemName: row.systemImage)
                .font(.title3)
                .foregroundStyle(Color(uiColor: UIColor(hex: 0x1C7AF5)))
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(Color(uiColor: UIColor(hex: 0x1C7AF5)).opacity(0.12))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                Text(row.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(row.amountFormatted)
                .font(.subheadline.monospacedDigit().weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private enum KeypadRole {
        case normal
        case destructive
        case muted

        var background: Color {
            switch self {
            case .normal: return Color(.tertiarySystemFill)
            case .destructive: return Color(.systemRed).opacity(0.14)
            case .muted: return Color(.secondarySystemFill)
            }
        }

        var foreground: Color {
            switch self {
            case .normal: return .primary
            case .destructive: return .red
            case .muted: return .secondary
            }
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
