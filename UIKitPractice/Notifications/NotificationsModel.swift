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
