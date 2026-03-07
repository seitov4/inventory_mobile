//
//  CategoryFilterButton.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 25.01.2026.
//

import UIKit

final class CategoryFilterButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        layer.cornerRadius = 18
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    }
    
    func configure(title: String, isSelected: Bool) {
        setTitle(title, for: .normal)
        
        if isSelected {
            backgroundColor = UIColor(red: 0.11, green: 0.48, blue: 0.96, alpha: 1.0) // #1C7AF5
            setTitleColor(.white, for: .normal)
        } else {
            backgroundColor = .secondarySystemBackground
            setTitleColor(.label, for: .normal)
        }
    }
}
