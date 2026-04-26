//
//  NotificationsView.swift
//  UIKitPractice
//

import Observation
import SwiftUI

struct NotificationsScreen: View {
    @Bindable var viewModel: NotificationsViewModel
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
                        Text(bucket.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
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
