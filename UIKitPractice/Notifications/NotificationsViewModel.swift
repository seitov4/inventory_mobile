//
//  NotificationsViewModel.swift
//  UIKitPractice
//

import Foundation
import Observation

@Observable
final class NotificationsViewModel {

    var items: [StoreNotificationItem]

    init() {
        items = Self.makeMock()
    }

    func markAllRead() {
        items = items.map { row in
            var r = row
            r.isUnread = false
            return r
        }
    }

    func markRead(_ item: StoreNotificationItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        var copy = items[i]
        copy.isUnread = false
        items[i] = copy
    }

    func items(for bucket: NotificationTimeBucket) -> [StoreNotificationItem] {
        items.filter { $0.bucket == bucket }
    }

    private static func makeMock() -> [StoreNotificationItem] {
        [
            StoreNotificationItem(
                id: "1",
                title: "Заканчивается срок годности",
                message: "12 позиций в категории «Молочные продукты» требуют внимания.",
                timeLabel: "09:42",
                systemImage: "calendar.badge.exclamationmark",
                tintHex: 0xF2994A,
                isUnread: true,
                bucket: .today
            ),
            StoreNotificationItem(
                id: "2",
                title: "Поставка принята",
                message: "Накладная № 18492 успешно проведена на склад «Основной».",
                timeLabel: "08:15",
                systemImage: "shippingbox.fill",
                tintHex: 0x1C7AF5,
                isUnread: true,
                bucket: .today
            ),
            StoreNotificationItem(
                id: "3",
                title: "Низкий остаток",
                message: "SKU «Вода 0,5 л» — осталось 8 шт., порог 24 шт.",
                timeLabel: "Вчера",
                systemImage: "cube.transparent.fill",
                tintHex: 0xEB5757,
                isUnread: false,
                bucket: .yesterday
            ),
            StoreNotificationItem(
                id: "4",
                title: "Отчёт готов",
                message: "Еженедельная аналитика по сменам доступна в разделе «Аналитика».",
                timeLabel: "Вчера",
                systemImage: "doc.text.fill",
                tintHex: 0x6FCF97,
                isUnread: false,
                bucket: .yesterday
            ),
            StoreNotificationItem(
                id: "5",
                title: "Обновление приложения",
                message: "Доступна версия 2.4 — улучшения кассы и офлайн-режима.",
                timeLabel: "Пн",
                systemImage: "arrow.down.circle.fill",
                tintHex: 0x9B51E0,
                isUnread: false,
                bucket: .week
            ),
            StoreNotificationItem(
                id: "6",
                title: "Смена закрыта",
                message: "Кассир А. Иванова закрыла смену № 412 с расхождением \(AppCurrency.string(from: 0)).",
                timeLabel: "Пн",
                systemImage: "checkmark.seal.fill",
                tintHex: 0x27AE60,
                isUnread: false,
                bucket: .week
            )
        ]
    }
}
