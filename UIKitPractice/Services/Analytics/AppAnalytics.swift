//
//  AppAnalytics.swift
//  UIKitPractice
//

import Foundation
import UIKit

enum AnalyticsEventName: String {
    case appLaunch = "app_launch"
    case loginAttempt = "login_attempt"
    case loginSuccess = "login_success"
    case loginFailure = "login_failure"
    case logout = "logout"
    case screenView = "screen_view"
    case languageChanged = "language_changed"
    case roleChanged = "role_changed"
    case productListLoaded = "product_list_loaded"
    case barcodeScanSuccess = "barcode_scan_success"
    case barcodeScanFailed = "barcode_scan_failed"
    case saleCheckoutStarted = "sale_checkout_started"
    case saleCompleted = "sale_completed"
    case aiChatOpened = "ai_chat_opened"
    case aiChatMessageSent = "ai_chat_message_sent"
    case aiChatReplyReceived = "ai_chat_reply_received"
    case aiChatReplyFailed = "ai_chat_reply_failed"
    case aiChatAttachmentAdded = "ai_chat_attachment_added"
    case notificationsChanged = "notifications_changed"
    case notificationOpened = "notification_opened"
    case notificationsMarkedAllRead = "notifications_marked_all_read"
    case themeChanged = "theme_changed"
    case biometricsChanged = "biometrics_changed"
}

enum AnalyticsPropertyValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    init(stringLiteral value: String) {
        self = .string(value)
    }

    init(integerLiteral value: Int) {
        self = .int(value)
    }

    init(floatLiteral value: Double) {
        self = .double(value)
    }

    init(booleanLiteral value: Bool) {
        self = .bool(value)
    }

    var objectValue: Any {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        }
    }
}

protocol AnalyticsProvider {
    func track(eventName: String, properties: [String: Any], userID: String?)
    func identify(userID: String?, properties: [String: Any])
}

final class AppAnalytics {
    static let shared = AppAnalytics()

    private let provider: AnalyticsProvider
    private var userID: String?
    private let queue = DispatchQueue(label: "com.inventix.analytics")

    private init() {
        let apiKey = (Bundle.main.object(forInfoDictionaryKey: "AMPLITUDE_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let apiKey, !apiKey.isEmpty {
            provider = AmplitudeHTTPAnalyticsProvider(apiKey: apiKey)
        } else {
            provider = DebugAnalyticsProvider()
        }
    }

    func track(_ eventName: AnalyticsEventName, properties: [String: AnalyticsPropertyValue] = [:]) {
        let preparedProperties = defaultProperties().merging(properties.objectValues) { _, new in new }
        queue.async { [provider, userID] in
            provider.track(eventName: eventName.rawValue, properties: preparedProperties, userID: userID)
        }
    }

    func trackScreen(_ screenName: String, properties: [String: AnalyticsPropertyValue] = [:]) {
        track(.screenView, properties: ["screen": .string(screenName)].merging(properties) { _, new in new })
    }

    func identify(userID: String?, properties: [String: AnalyticsPropertyValue] = [:]) {
        self.userID = userID
        let preparedProperties = defaultProperties().merging(properties.objectValues) { _, new in new }
        queue.async { [provider] in
            provider.identify(userID: userID, properties: preparedProperties)
        }
    }

    private func defaultProperties() -> [String: Any] {
        [
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            "language": LocalizationManager.shared.currentLanguage.rawValue,
            "role": UserSessionManager.shared.currentRole.rawValue,
            "platform": "ios",
            "device_model": UIDevice.current.model,
            "system_version": UIDevice.current.systemVersion,
            "country_code": Locale.current.regionCode ?? "unknown",
            "locale": Locale.current.identifier,
            "preferred_language": Locale.preferredLanguages.first ?? "unknown",
            "time_zone": TimeZone.current.identifier
        ]
    }
}

private extension Dictionary where Key == String, Value == AnalyticsPropertyValue {
    var objectValues: [String: Any] {
        mapValues(\.objectValue)
    }
}

private final class AmplitudeHTTPAnalyticsProvider: AnalyticsProvider {
    private let apiKey: String
    private let endpoint = URL(string: "https://api2.amplitude.com/2/httpapi")!
    private let deviceIDKey = "analytics_device_id"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func track(eventName: String, properties: [String: Any], userID: String?) {
        send(
            eventType: eventName,
            userID: userID,
            eventProperties: properties,
            userProperties: nil
        )
    }

    func identify(userID: String?, properties: [String: Any]) {
        send(
            eventType: "$identify",
            userID: userID,
            eventProperties: [:],
            userProperties: properties
        )
    }

    private func send(
        eventType: String,
        userID: String?,
        eventProperties: [String: Any],
        userProperties: [String: Any]?
    ) {
        var event: [String: Any] = [
            "device_id": deviceID,
            "event_type": eventType,
            "event_properties": eventProperties,
            "time": Int(Date().timeIntervalSince1970 * 1000)
        ]

        if let userID, !userID.isEmpty {
            event["user_id"] = userID
        }

        if let userProperties {
            event["user_properties"] = userProperties
        }

        let payload: [String: Any] = [
            "api_key": apiKey,
            "events": [event]
        ]

        guard JSONSerialization.isValidJSONObject(payload),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request).resume()
    }

    private var deviceID: String {
        if let existing = UserDefaults.standard.string(forKey: deviceIDKey), !existing.isEmpty {
            return existing
        }

        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: deviceIDKey)
        return generated
    }
}

private final class DebugAnalyticsProvider: AnalyticsProvider {
    func track(eventName: String, properties: [String: Any], userID: String?) {
        #if DEBUG
        print("[Analytics] event:", eventName, "user:", userID ?? "anonymous", "properties:", properties)
        #endif
    }

    func identify(userID: String?, properties: [String: Any]) {
        #if DEBUG
        print("[Analytics] identify:", userID ?? "anonymous", "properties:", properties)
        #endif
    }
}
