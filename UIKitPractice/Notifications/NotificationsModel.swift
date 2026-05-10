//
//  NotificationsModel.swift
//  UIKitPractice
//

import Foundation

enum NotificationTimeBucket: String, CaseIterable, Identifiable {
    case today = "Сегодня"
    case yesterday = "Вчера"
    case week = "На этой неделе"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return L10n.tr("notifications.today")
        case .yesterday: return L10n.tr("notifications.yesterday")
        case .week: return L10n.tr("notifications.week")
        }
    }
}

struct StoreNotificationItem: Identifiable {
    let id: String
    let title: String
    let message: String
    let timeLabel: String
    let systemImage: String
    let tintHex: UInt32
    var isUnread: Bool
    let bucket: NotificationTimeBucket
}
