//
//  UserSessionManager.swift
//  UIKitPractice
//

import Foundation

enum AppTab: Int, CaseIterable {
    case analytics = 0
    case products = 1
    case sales = 2
    case notifications = 3
    case profile = 4

    var titleKey: String {
        switch self {
        case .analytics: return "tab.analytics"
        case .products: return "tab.products"
        case .sales: return "tab.sales"
        case .notifications: return "tab.notifications"
        case .profile: return "tab.profile"
        }
    }

    var systemImage: String {
        switch self {
        case .analytics: return "chart.bar.fill"
        case .products: return "cube.fill"
        case .sales: return "qrcode.viewfinder"
        case .notifications: return "bell.fill"
        case .profile: return "person.fill"
        }
    }
}

enum AppUserRole: String, CaseIterable, Identifiable {
    case owner
    case admin
    case employee

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .owner: return L10n.tr("role.owner")
        case .admin: return L10n.tr("role.admin")
        case .employee: return L10n.tr("role.employee")
        }
    }

    var allowedTabs: [AppTab] {
        switch self {
        case .owner:
            return [.analytics, .products, .sales, .notifications, .profile]
        case .admin:
            return [.products, .sales, .notifications, .profile]
        case .employee:
            return [.sales, .notifications, .profile]
        }
    }

    var canViewEnterprise: Bool {
        self != .employee
    }

    var canManageStaff: Bool {
        self == .owner || self == .admin
    }

    var canViewAnalytics: Bool {
        self == .owner
    }

    static func fromBackendRole(_ rawRole: String) -> AppUserRole {
        let normalized = rawRole
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if ["owner", "chief", "director", "superadmin", "boss", "главный", "владелец", "начальник"].contains(normalized) {
            return .owner
        }

        if ["admin", "administrator", "админ", "администратор", "manager", "менеджер"].contains(normalized) {
            return .admin
        }

        return .employee
    }
}

extension Notification.Name {
    static let appUserRoleDidChange = Notification.Name("appUserRoleDidChange")
}

final class UserSessionManager {
    static let shared = UserSessionManager()

    private let roleKey = "app_user_role"

    private init() {}

    var currentRole: AppUserRole {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: roleKey),
                  let role = AppUserRole(rawValue: rawValue) else {
                return .owner
            }
            return role
        }
        set {
            guard Thread.isMainThread else {
                DispatchQueue.main.async { [weak self] in
                    self?.currentRole = newValue
                }
                return
            }

            UserDefaults.standard.set(newValue.rawValue, forKey: roleKey)
            NotificationCenter.default.post(name: .appUserRoleDidChange, object: newValue)
        }
    }

    func updateRole(fromBackend rawRole: String) {
        currentRole = AppUserRole.fromBackendRole(rawRole)
    }

    func ensureMockRoleIfNeeded() {
        guard UserDefaults.standard.string(forKey: roleKey) == nil else { return }
        currentRole = .owner
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: roleKey)
    }
}
