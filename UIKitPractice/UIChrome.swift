//
//  UIChrome.swift
//  UIKitPractice
//

import SwiftUI

/// Тени и акценты, которые читаются и в светлой, и в тёмной теме.
enum UIChrome {
    static func cardShadowColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
    }
}
