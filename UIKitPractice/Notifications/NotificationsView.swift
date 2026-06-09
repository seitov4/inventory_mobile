//
//  NotificationsView.swift
//  UIKitPractice
//

import Observation
import SwiftUI

struct NotificationsScreen: View {
    @Bindable var viewModel: NotificationsViewModel
    let onOpenReports: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            ForEach(NotificationTimeBucket.allCases) { bucket in
                let rows = viewModel.items(for: bucket)
                if !rows.isEmpty {
                    Section {
                        ForEach(rows) { item in
                            notificationRow(item)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.markRead(item)
                                }
                        }
                    } header: {
                        Text(bucket.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
            }

            if UserSessionManager.shared.currentRole == .owner {
                reportsBanner
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 18, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            AppAnalytics.shared.trackScreen("notifications")
        }
        .appLocalized()
    }

    private func notificationRow(_ item: StoreNotificationItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: UIColor(hex: item.tintHex)).opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: item.systemImage)
                    .font(.title3)
                    .foregroundStyle(Color(uiColor: UIColor(hex: item.tintHex)))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Text(item.timeLabel)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Text(item.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if item.isUnread {
                Circle()
                    .fill(Color(uiColor: UIColor(hex: 0x1C7AF5)))
                    .frame(width: 9, height: 9)
                    .padding(.top, 6)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 6, y: 2)
        }
    }

    private var reportsBanner: some View {
        Button(action: onOpenReports) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(ReportsBannerPalette.gradient)
                    .shadow(color: ReportsBannerPalette.shadow.opacity(colorScheme == .dark ? 0.18 : 0.24), radius: 14, y: 7)

                Circle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 112, height: 112)
                    .offset(x: 150, y: -42)

                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(.white.opacity(0.18))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 25, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(.white.opacity(0.9))
                                .frame(width: 5, height: 5)
                            Text(L10n.tr("reports.banner.badge"))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.96))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.14), in: Capsule())

                        Text(L10n.tr("reports.owner_title"))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(L10n.tr("reports.notifications_banner_subtitle"))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(2)
                    }
                    .layoutPriority(1)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.88))
                }
                .padding(16)
            }
            .frame(minHeight: 122)
        }
        .buttonStyle(ReportsBannerButtonStyle())
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
