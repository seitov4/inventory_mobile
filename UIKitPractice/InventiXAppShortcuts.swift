import AppIntents
import Foundation

struct InventiXAppShortcutsProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenSalesScreenIntent(),
            phrases: [
                "Открыть продажу в \(.applicationName)",
                "Сканер \(.applicationName)"
            ],
            shortTitle: "Продажа",
            systemImageName: "barcode.viewfinder"
        )

        AppShortcut(
            intent: OpenProductsScreenIntent(),
            phrases: [
                "Открыть товары в \(.applicationName)",
                "Товары \(.applicationName)"
            ],
            shortTitle: "Товары",
            systemImageName: "shippingbox.fill"
        )

        AppShortcut(
            intent: OpenAnalyticsScreenIntent(),
            phrases: [
                "Открыть аналитику в \(.applicationName)",
                "Аналитика \(.applicationName)"
            ],
            shortTitle: "Аналитика",
            systemImageName: "chart.line.uptrend.xyaxis"
        )

        AppShortcut(
            intent: OpenNotificationsScreenIntent(),
            phrases: [
                "Открыть уведомления в \(.applicationName)",
                "Уведомления \(.applicationName)"
            ],
            shortTitle: "Уведомления",
            systemImageName: "bell.badge.fill"
        )
    }
}

struct OpenSalesScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть продажу"
    static let description = IntentDescription("Открывает экран продажи InventiX.")
    static let supportedModes: IntentModes = .foreground(.dynamic)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        AppShortcutRouteStore.savePendingRoute(.quickSale)
        try await continueInForeground(alwaysConfirm: false)
        return .result()
    }
}

struct OpenProductsScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть товары"
    static let description = IntentDescription("Открывает каталог товаров InventiX.")
    static let supportedModes: IntentModes = .foreground(.dynamic)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        AppShortcutRouteStore.savePendingRoute(.products)
        try await continueInForeground(alwaysConfirm: false)
        return .result()
    }
}

struct OpenAnalyticsScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть аналитику"
    static let description = IntentDescription("Открывает аналитику InventiX.")
    static let supportedModes: IntentModes = .foreground(.dynamic)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        AppShortcutRouteStore.savePendingRoute(.analytics)
        try await continueInForeground(alwaysConfirm: false)
        return .result()
    }
}

struct OpenNotificationsScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть уведомления"
    static let description = IntentDescription("Открывает уведомления InventiX.")
    static let supportedModes: IntentModes = .foreground(.dynamic)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        AppShortcutRouteStore.savePendingRoute(.notifications)
        try await continueInForeground(alwaysConfirm: false)
        return .result()
    }
}
