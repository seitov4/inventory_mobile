//
//  EditProfileView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit

final class EditProfileView: UIView {

    // Делаем поля публичными и с правильными настройками
    let nameField = UITextField()
    let emailField = UITextField()
    
    let saveButton = UIButton(type: .system)

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .systemBackground
        
        // === ScrollView ===
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // === Поля ввода ===
        nameField.configureModernField(placeholder: "Ваше имя", icon: "person")
        emailField.configureModernField(placeholder: "Email", icon: "envelope", keyboardType: .emailAddress)
        
        // === Кнопка Сохранить ===
        var config = UIButton.Configuration.filled()
        config.title = "Сохранить изменения"
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 18, weight: .semibold)
            return outgoing
        }
        
        saveButton.configuration = config
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.layer.shadowColor = UIColor.systemBlue.cgColor
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        saveButton.layer.shadowRadius = 20
        saveButton.layer.shadowOpacity = 0.25
        
        // === Стек ===
        let stack = UIStackView(arrangedSubviews: [nameField, emailField, saveButton])
        stack.axis = .vertical
        stack.spacing = 28
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        
        // === Констрейнты ===
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -40)
        ])
        
        // КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: разрешаем взаимодействие
        saveButton.isEnabled = true
        nameField.isUserInteractionEnabled = true
        emailField.isUserInteractionEnabled = true
        
        // Анимация кнопки
        saveButton.addTarget(self, action: #selector(buttonDown), for: .touchDown)
        saveButton.addTarget(self, action: #selector(buttonUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func buttonDown() {
        UIView.animate(withDuration: 0.15) {
            self.saveButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.saveButton.alpha = 0.9
        }
    }
    
    @objc private func buttonUp() {
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.65,
            initialSpringVelocity: 0.5,
            options: .allowUserInteraction,
            animations: {
                self.saveButton.transform = .identity
                self.saveButton.alpha = 1.0  
            },
            completion: nil
        )
    }
}

// MARK: - Удобное расширение для полей
extension UITextField {
    func configureModernField(placeholder: String, icon: String, keyboardType: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.font = .systemFont(ofSize: 17)
        self.backgroundColor = .secondarySystemGroupedBackground
        self.layer.cornerRadius = 14
        self.heightAnchor.constraint(equalToConstant: 56).isActive = true
        self.clearButtonMode = .whileEditing
        self.autocapitalizationType = .words
        self.returnKeyType = .done
        
        // Иконка слева
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .center
        
        let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        iconView.frame = leftContainer.bounds
        leftContainer.addSubview(iconView)
        
        self.leftView = leftContainer
        self.leftViewMode = .always
        
        // Отступ справа
        let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        self.rightView = rightPadding
        self.rightViewMode = .always
    }
}
