//
//  UIColor+InterfaceStyle.swift
//  UIKitPractice
//

import UIKit

extension UIColor {
    /// Тень под карточками: в тёмной теме светлый ореол вместо «грязного» чёрного.
    static func adaptiveCardShadowBase() -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.18)
                : UIColor.black.withAlphaComponent(0.22)
        }
    }

    static func adaptiveSearchBarFill() -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.tertiarySystemFill
                : UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1)
        }
    }

    static func adaptiveTintBlueBackground() -> UIColor {
        UIColor { traits in
            let blue = UIColor(red: 0.11, green: 0.48, blue: 0.96, alpha: 1)
            return traits.userInterfaceStyle == .dark
                ? blue.withAlphaComponent(0.28)
                : blue.withAlphaComponent(0.15)
        }
    }

    static func adaptiveLowStockCardBackground() -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.22, blue: 0.16, alpha: 1)
                : UIColor(red: 0.91, green: 0.98, blue: 0.89, alpha: 1)
        }
    }

    static func adaptiveIconTileBackground() -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.tertiarySystemFill
                : UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        }
    }
}
