//
//  WelcomeView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit
final class WelcomeView: UIView {
    
    let stack = UIStackView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let loginButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    
    private func setup() {
        backgroundColor = .systemBackground
        
        
        titleLabel.text = "Система учета товаров"
        titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Войти или зарегистрироваться"
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        var loginConfig = UIButton.Configuration.bordered()
        loginConfig.title = "Войти"
        loginConfig.baseForegroundColor = .systemBlue
        loginConfig.cornerStyle = .medium
        loginConfig.contentInsets = NSDirectionalEdgeInsets(top:14, leading: 24, bottom: 14, trailing: 24)
        loginButton.configuration = loginConfig
        
        
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.addArrangedSubview(loginButton)
        
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            
            loginButton.widthAnchor.constraint(equalTo: stack.widthAnchor),
            titleLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            subtitleLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        
        loginButton.setTitleColor(.systemBlue, for: .normal)
    }
}
