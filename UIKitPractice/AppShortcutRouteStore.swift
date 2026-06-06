import Foundation

enum AppShortcutRouteStore {
    private static let suiteName = "group.Nurseit.UIKitPractice"
    private static let pendingRouteKey = "inventix.pendingShortcutRoute"

    static func savePendingRoute(_ route: AppShortcutRoute) {
        write(route.rawValue)
    }

    static func savePendingRoute(rawValue: String) {
        write(rawValue)
    }

    static func loadPendingRoute() -> AppShortcutRoute? {
        guard let rawValue = readRawValue(),
              let route = AppShortcutRoute(rawValue: rawValue) else {
            return nil
        }

        return route
    }

    static func clearPendingRoute() {
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: pendingRouteKey)
        UserDefaults.standard.removeObject(forKey: pendingRouteKey)
        UserDefaults(suiteName: suiteName)?.synchronize()
        UserDefaults.standard.synchronize()
    }

    private static func write(_ rawValue: String) {
        UserDefaults(suiteName: suiteName)?.set(rawValue, forKey: pendingRouteKey)
        UserDefaults.standard.set(rawValue, forKey: pendingRouteKey)
        UserDefaults(suiteName: suiteName)?.synchronize()
        UserDefaults.standard.synchronize()
    }

    private static func readRawValue() -> String? {
        UserDefaults(suiteName: suiteName)?.string(forKey: pendingRouteKey)
            ?? UserDefaults.standard.string(forKey: pendingRouteKey)
    }
}
