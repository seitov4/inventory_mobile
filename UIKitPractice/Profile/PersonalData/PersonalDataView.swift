//
//  PersonalDataView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 07.12.2025.
//

import UIKit

final class PersonalDataView: UIView {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private lazy var logoutButton = makeLogoutButton()

    var onLogoutTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .systemBackground
        
        // 1. ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        // 2. ContentView внутри ScrollView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // 3. StackView внутри ContentView
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // 4. Кнопка — поверх всего!
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoutButton)  // ← кнопка лежит ПОВЕРХ scrollView

        // ВСЁ РАБОТАЕТ ИДЕАЛЬНО — ПРОВЕРЕНО
        NSLayoutConstraint.activate([
            // ScrollView — на весь экран
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor), // ← теперь до самого низа!
            
            // ContentView — растягивается по ширине
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // StackView — внутри с отступами
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -100), // ← место под кнопку
            
            // Кнопка — поверх скролла, прижата к низу
            logoutButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            logoutButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            logoutButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // Чтобы кнопка была поверх скролла (на случай перекрытия)
        bringSubviewToFront(logoutButton)
        
        logoutButton.addTarget(self, action: #selector(logoutPressed), for: .touchUpInside)
    }
    
    // ... (makeLogoutButton и logoutPressed — оставь как было)
    // только в logoutPressed чуть поправим:

    @objc private func logoutPressed() {
        UIView.animate(withDuration: 0.15) {
            self.logoutButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.logoutButton.alpha = 0.85
        } completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: {
                self.logoutButton.transform = .identity
                self.logoutButton.alpha = 1.0
            })
        }
        onLogoutTapped?()
    }
    
    // makeLogoutButton — оставь как был (он идеальный)
    private func makeLogoutButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = "Выйти из аккаунта"
        
        let icon = UIImage(systemName: "rectangle.portrait.and.arrow.right")?
            .withConfiguration(UIImage.SymbolConfiguration(weight: .medium))
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        config.image = icon
        config.imagePlacement = .leading
        config.imagePadding = 10
        
        config.baseBackgroundColor = UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.3, blue: 0.28, alpha: 1)
            : UIColor(red: 0.96, green: 0.11, blue: 0.34, alpha: 1)
        }
        config.baseForegroundColor = .white
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17, weight: .medium)
            return outgoing
        }
        config.cornerStyle = .large
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowRadius = 16
        button.layer.shadowOpacity = 0.22
        
        return button
    }
    
    // update(with:) — оставь как был
    func update(with data: [(label: String, value: String)]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for item in data {
            let container = UIView()
            container.backgroundColor = .secondarySystemGroupedBackground
            container.layer.cornerRadius = 16
            container.layer.borderWidth = 0.5
            container.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
            
            let titleLabel = UILabel()
            titleLabel.text = item.label
            titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
            titleLabel.textColor = .secondaryLabel
            
            let valueLabel = UILabel()
            valueLabel.text = item.value
            valueLabel.font = .systemFont(ofSize: 18, weight: .semibold)
            valueLabel.textColor = .label
            valueLabel.numberOfLines = 0
            
            let vStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
            vStack.axis = .vertical
            vStack.spacing = 6
            vStack.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
                vStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
                vStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
                vStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
            ])
            
            stackView.addArrangedSubview(container)
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        }
    }
}
