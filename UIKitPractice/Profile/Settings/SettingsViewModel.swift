//
//  SettingsViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import Foundation

final class SettingsViewModel {
    private let notificationsKey = "profile_notifications"
    var currentNotifications: Bool {
        get { UserDefaults.standard.bool(forKey: notificationsKey) }
        set { UserDefaults.standard.set(newValue, forKey: notificationsKey) }
    }

    var currentAppearanceIndex: Int {
        get { ThemeManager.shared.currentTheme.rawValue }
        set { ThemeManager.shared.currentTheme = AppTheme(rawValue: newValue) ?? .system }
    }

    func updateAppearance(_ raw: Int) {
        ThemeManager.shared.currentTheme = AppTheme(rawValue: raw) ?? .system
    }

    func toggleNotifications(_ isOn: Bool) {
        currentNotifications = isOn
    }
}
