//
//  LocalizationManager.swift
//  UIKitPractice
//

import Foundation
import ObjectiveC
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case ru
    case en
    case kk

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        case .kk: return "Қазақша"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .ru: return "ru"
        case .en: return "en"
        case .kk: return "kk"
        }
    }
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("appLanguageDidChange")
}

final class LocalizationManager {
    static let shared = LocalizationManager()

    private let languageKey = "app_language_code"

    private init() {}

    var currentLanguage: AppLanguage {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: languageKey),
                  let language = AppLanguage(rawValue: rawValue) else {
                return .ru
            }
            return language
        }
        set {
            let oldValue = currentLanguage
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
            UserDefaults.standard.set([newValue.localeIdentifier], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            Bundle.setAppLanguage(newValue.localeIdentifier)
            NotificationCenter.default.post(name: .appLanguageDidChange, object: newValue)
            if oldValue != newValue {
                AppAnalytics.shared.track(.languageChanged, properties: [
                    "from": .string(oldValue.rawValue),
                    "to": .string(newValue.rawValue)
                ])
            }
        }
    }

    func applySavedLanguage() {
        Bundle.setAppLanguage(currentLanguage.localeIdentifier)
    }
}

enum L10n {
    static func tr(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: tr(key),
            locale: Locale(identifier: LocalizationManager.shared.currentLanguage.localeIdentifier),
            arguments: arguments
        )
    }
}

private struct AppLocalizedModifier: ViewModifier {
    @State private var language = LocalizationManager.shared.currentLanguage

    func body(content: Content) -> some View {
        content
            .environment(\.locale, Locale(identifier: language.localeIdentifier))
            .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { notification in
                if let language = notification.object as? AppLanguage {
                    self.language = language
                }
            }
    }
}

extension View {
    func appLocalized() -> some View {
        modifier(AppLocalizedModifier())
    }
}

private var appLanguageBundleKey: UInt8 = 0

private final class AppLanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let path = objc_getAssociatedObject(self, &appLanguageBundleKey) as? String,
              let bundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }

        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

private extension Bundle {
    static func setAppLanguage(_ languageCode: String) {
        defer { object_setClass(Bundle.main, AppLanguageBundle.self) }

        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") else {
            objc_setAssociatedObject(Bundle.main, &appLanguageBundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }

        objc_setAssociatedObject(Bundle.main, &appLanguageBundleKey, path, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
