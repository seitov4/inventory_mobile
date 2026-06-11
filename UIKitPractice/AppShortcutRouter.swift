import Foundation

enum AppShortcutRoute: String {
    case analytics = "com.inventix.shortcut.analytics"
    case aiChat = "com.inventix.shortcut.aiChat"
    case products = "com.inventix.shortcut.products"
    case quickSale = "com.inventix.shortcut.quickSale"
    case myEnterprise = "com.inventix.shortcut.myEnterprise"
    case notifications = "com.inventix.shortcut.notifications"

    init?(shortcutType: String) {
        self.init(rawValue: shortcutType)
    }

    init?(deepLink url: URL) {
        guard url.scheme == "inventix" else { return nil }
        let route = url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.init(identifier: route)
    }

    init?(identifier: String) {
        switch identifier {
        case "analytics":
            self = .analytics
        case "ai-chat", "aiChat", "chat", "assistant", "ai-assistant":
            self = .aiChat
        case "products":
            self = .products
        case "sales", "sale", "quick-sale", "quickSale":
            self = .quickSale
        case "notifications":
            self = .notifications
        case "enterprise", "my-enterprise", "myEnterprise":
            self = .myEnterprise
        default:
            return nil
        }
    }
}

final class AppShortcutRouter {
    static let shared = AppShortcutRouter()
    private init() {}

    var pendingRoute: AppShortcutRoute?

    func enqueue(_ route: AppShortcutRoute) {
        pendingRoute = route
        AppShortcutRouteStore.savePendingRoute(route)
    }

    func reloadPersistedRouteIfNeeded() {
        guard pendingRoute == nil else { return }
        pendingRoute = AppShortcutRouteStore.loadPendingRoute()
    }

    func markHandled(_ route: AppShortcutRoute) {
        if pendingRoute == route {
            pendingRoute = nil
        }
        AppShortcutRouteStore.clearPendingRoute()
    }
}

extension Notification.Name {
    static let appShortcutTriggered = Notification.Name("appShortcutTriggered")
}
