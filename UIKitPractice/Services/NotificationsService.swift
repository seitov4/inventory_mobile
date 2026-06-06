//
//  NotificationsService.swift
//  UIKitPractice
//

import Foundation

private struct BackendNotificationDTO: Decodable {
    let id: Int
    let type: String
    let status: String
    let payload: Payload?
    let createdAt: String?

    struct Payload: Decodable {
        let quantity: Int?
        let minStock: Int?
        let productID: Int?
        let productName: String?
        let warehouseID: Int?

        private enum CodingKeys: String, CodingKey {
            case quantity
            case minStock = "min_stock"
            case productID = "product_id"
            case productName = "product_name"
            case warehouseID = "warehouse_id"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case status
        case payload
        case createdAt = "created_at"
    }

    var item: StoreNotificationItem {
        StoreNotificationItem(
            id: String(id),
            title: title,
            message: message,
            timeLabel: Self.timeLabel(from: createdAt),
            systemImage: systemImage,
            tintHex: tintHex,
            isUnread: status.uppercased() == "UNREAD",
            bucket: Self.bucket(from: createdAt)
        )
    }

    private var title: String {
        switch type.uppercased() {
        case "LOW_STOCK":
            return L10n.tr("notifications.low_stock_title")
        default:
            return type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private var message: String {
        switch type.uppercased() {
        case "LOW_STOCK":
            let product = payload?.productName ?? "SKU"
            let quantity = payload?.quantity ?? 0
            let threshold = payload?.minStock ?? 0
            return "\(product): \(quantity) / \(threshold)"
        default:
            return payload.map { "\($0)" } ?? title
        }
    }

    private var systemImage: String {
        switch type.uppercased() {
        case "LOW_STOCK":
            return "cube.transparent.fill"
        default:
            return "bell.fill"
        }
    }

    private var tintHex: UInt32 {
        switch type.uppercased() {
        case "LOW_STOCK":
            return 0xEB5757
        default:
            return 0x1C7AF5
        }
    }

    private static func bucket(from value: String?) -> NotificationTimeBucket {
        guard let date = parseDate(value) else { return .week }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return .today }
        if calendar.isDateInYesterday(date) { return .yesterday }
        return .week
    }

    private static func timeLabel(from value: String?) -> String {
        guard let date = parseDate(value) else { return "" }
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "dd.MM"
        }
        return formatter.string(from: date)
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}

final class NotificationsService {
    static let shared = NotificationsService()

    private init() {}

    func fetchNotifications(completion: @escaping (Result<[StoreNotificationItem], Error>) -> Void) {
        APIClient.shared.requestEnvelope(endpoint: "notifications") { (result: Result<[BackendNotificationDTO], Error>) in
            completion(result.map { $0.map(\.item) })
        }
    }

    func markRead(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        APIClient.shared.requestEnvelope(
            endpoint: "notifications/\(id)/read",
            method: "PUT"
        ) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }
}

private struct EmptyResponse: Decodable {}
