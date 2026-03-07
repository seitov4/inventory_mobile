//
//  ThemeManager.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 07.12.2025.
//

import UIKit

enum AppTheme: Int {
    case system = 0
    case light = 1
    case dark = 2
}

final class ThemeManager {
    static let shared = ThemeManager()
    private init() {}

    private let key = "app_theme_key"

    var currentTheme: AppTheme {
        get {
            let raw = UserDefaults.standard.integer(forKey: key)
            return AppTheme(rawValue: raw) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            applyTheme(newValue)
        }
    }

    func applySavedTheme() {
        applyTheme(currentTheme)
    }

    func applyTheme(_ theme: AppTheme) {
        guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else { return }

        switch theme {
        case .system: window.overrideUserInterfaceStyle = .unspecified
        case .light:  window.overrideUserInterfaceStyle = .light
        case .dark:   window.overrideUserInterfaceStyle = .dark
        }
    }
}
