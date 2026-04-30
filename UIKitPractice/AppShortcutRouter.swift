import Foundation

enum AppShortcutRoute: String {
    case quickSale = "com.inventix.shortcut.quickSale"
    case myEnterprise = "com.inventix.shortcut.myEnterprise"
    case notifications = "com.inventix.shortcut.notifications"

    init?(shortcutType: String) {
        self.init(rawValue: shortcutType)
    }
}

final class AppShortcutRouter {
    static let shared = AppShortcutRouter()
    private init() {}

    var pendingRoute: AppShortcutRoute?
}

extension Notification.Name {
    static let appShortcutTriggered = Notification.Name("appShortcutTriggered")
}

