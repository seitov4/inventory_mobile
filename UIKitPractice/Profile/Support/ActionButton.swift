//
//  ActionButton.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 08.12.2025.
//

import Foundation
import UIKit

final class ActionButton: UIButton {
    var action: (() -> Void)?

    @objc private func handleTap() {
        action?()
    }

    func setAction(_ action: @escaping () -> Void) {
        self.action = action
        self.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
}
