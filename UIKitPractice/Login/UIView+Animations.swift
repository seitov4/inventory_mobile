//
//  UIView+Animations.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 27.11.2025.
//

import UIKit

extension UIView {
    func shake(duration: CFTimeInterval = 0.4, pathLength: CGFloat = 8) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration = duration
        anim.values = [-pathLength, pathLength, -pathLength * 0,7, pathLength * 0,7, -pathLength * 0.4, pathLength * 0.4, 0]
        layer.add(anim, forKey: "shake")
    }
}
