//
//  NotificationsViewModel.swift
//  UIKitPractice
//

import Foundation
import Observation

@Observable
final class NotificationsViewModel {

    var items: [StoreNotificationItem]
    private var languageObserver: NSObjectProtocol?

    init() {
        items = Self.makeMock()
        languageObserver = NotificationCenter.default.addObserver(
            forName: .appLanguageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadLocalizedItems()
        }
    }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    func markAllRead() {
        items = items.map { row in
            var r = row
            r.isUnread = false
            return r
        }
        AppAnalytics.shared.track(.notificationsMarkedAllRead, properties: [
            "count": .int(items.count)
        ])
    }

    func markRead(_ item: StoreNotificationItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        var copy = items[i]
        copy.isUnread = false
        items[i] = copy
        AppAnalytics.shared.track(.notificationOpened, properties: [
            "notification_id": .string(item.id),
            "bucket": .string(item.bucket.analyticsValue),
            "was_unread": .bool(item.isUnread)
        ])
    }

    func items(for bucket: NotificationTimeBucket) -> [StoreNotificationItem] {
        items.filter { $0.bucket == bucket }
    }

    private func reloadLocalizedItems() {
        let unreadByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.isUnread) })
        items = Self.makeMock().map { item in
            var copy = item
            copy.isUnread = unreadByID[item.id] ?? item.isUnread
            return copy
        }
    }

    private static func makeMock() -> [StoreNotificationItem] {
        [
            StoreNotificationItem(
                id: "1",
                title: L10n.tr("notifications.expiry_title"),
                message: L10n.tr("notifications.expiry_message"),
                timeLabel: "09:42",
                systemImage: "calendar.badge.exclamationmark",
                tintHex: 0xF2994A,
                isUnread: true,
                bucket: .today
            ),
            StoreNotificationItem(
                id: "2",
                title: L10n.tr("notifications.delivery_title"),
                message: L10n.tr("notifications.delivery_message"),
                timeLabel: "08:15",
                systemImage: "shippingbox.fill",
                tintHex: 0x1C7AF5,
                isUnread: true,
                bucket: .today
            ),
            StoreNotificationItem(
                id: "3",
                title: L10n.tr("notifications.low_stock_title"),
                message: L10n.tr("notifications.low_stock_message"),
                timeLabel: L10n.tr("notifications.yesterday"),
                systemImage: "cube.transparent.fill",
                tintHex: 0xEB5757,
                isUnread: false,
                bucket: .yesterday
            ),
            StoreNotificationItem(
                id: "4",
                title: L10n.tr("notifications.report_title"),
                message: L10n.tr("notifications.report_message"),
                timeLabel: L10n.tr("notifications.yesterday"),
                systemImage: "doc.text.fill",
                tintHex: 0x6FCF97,
                isUnread: false,
                bucket: .yesterday
            ),
            StoreNotificationItem(
                id: "5",
                title: L10n.tr("notifications.update_title"),
                message: L10n.tr("notifications.update_message"),
                timeLabel: L10n.tr("notifications.monday"),
                systemImage: "arrow.down.circle.fill",
                tintHex: 0x9B51E0,
                isUnread: false,
                bucket: .week
            ),
            StoreNotificationItem(
                id: "6",
                title: L10n.tr("notifications.shift_closed_title"),
                message: L10n.format("notifications.shift_closed_message_format", AppCurrency.string(from: 0)),
                timeLabel: L10n.tr("notifications.monday"),
                systemImage: "checkmark.seal.fill",
                tintHex: 0x27AE60,
                isUnread: false,
                bucket: .week
            )
        ]
    }
}

private extension NotificationTimeBucket {
    var analyticsValue: String {
        switch self {
        case .today: return "today"
        case .yesterday: return "yesterday"
        case .week: return "week"
        }
    }
}
