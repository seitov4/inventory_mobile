//
//  LoginView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 21.11.2025.
//

import UIKit

final class LoginView: UIView {
    
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    
    let emailField = UITextField()
    let emailErrorLabel = UILabel()
    let passwordField = UITextField()
    let passwordErrorLabel = UILabel()
    
    let loginButton = UIButton(type: .system)
    let forgorPasswordButton = UIButton(type: .system)
    
    private let cardView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        titleLabel.text = "Добро пожаловать"
        titleLabel.font = .systemFont(ofSize: 32, weight: .regular)
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Войдите в систему"
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        
        cardView.backgroundColor = .secondarySystemGroupedBackground
        cardView.layer.cornerRadius = 14
        
        emailField.placeholder = "Email"
        emailField.borderStyle = .roundedRect
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.returnKeyType = .next
        
        emailErrorLabel.font = .systemFont(ofSize: 12)
        emailErrorLabel.textColor = .systemRed
        emailErrorLabel.numberOfLines = 1
        emailErrorLabel.isHidden = true
        
        passwordField.placeholder = "Пароль"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect
        passwordField.returnKeyType = .done
        
        setupPasswordVisibilityToggle()
        
        passwordErrorLabel.font = .systemFont(ofSize: 12)
        passwordErrorLabel.textColor = .systemRed
        passwordErrorLabel.numberOfLines = 1
        passwordErrorLabel.isHidden = true
        
        //MARK: Buttons
        var config = UIButton.Configuration.filled()
        config.title = "Войти"
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top:12, leading: 20, bottom: 12, trailing: 20)
        loginButton.configuration = config
        loginButton.isEnabled = false
        
        forgorPasswordButton.setTitle("Заыли пароль?", for: .normal)
        forgorPasswordButton.setTitleColor(.systemBlue, for: .normal)
        forgorPasswordButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        
        setupLayout()
    }
    
    private func setupPasswordVisibilityToggle() {
        let eyeButton = UIButton(type: .system)
        eyeButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        eyeButton.tintColor = .secondaryLabel
        eyeButton.frame = CGRect(x:0, y:0, width: 20, height: 20)
        eyeButton.imageView?.contentMode = .scaleAspectFit
        eyeButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        passwordField.rightView = eyeButton
        passwordField.rightViewMode = .always
    }
    
    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        passwordField.isSecureTextEntry.toggle()
        let imageName = passwordField.isSecureTextEntry ? "eye.fill" : "eye.slash.fill"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
        
        if let text = passwordField.text, passwordField.isSecureTextEntry {
            passwordField.text?.removeAll()
            passwordField.insertText(text)
        }
    }
    
    
    private func setupLayout() {
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 6
        headerStack.alignment = .center
        
        let emailStack = UIStackView(arrangedSubviews: [emailField, emailErrorLabel])
        emailStack.axis = .vertical
        emailStack.spacing = 6
        
        let passwordStack = UIStackView(arrangedSubviews: [passwordField, passwordErrorLabel])
        passwordStack.axis = .vertical
        passwordStack.spacing = 6
        
        let fieldStack = UIStackView(arrangedSubviews: [emailField, passwordField])
        fieldStack.axis = .vertical
        fieldStack.spacing = 12
        
        cardView.addSubview(fieldStack)
        fieldStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fieldStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            fieldStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            fieldStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            fieldStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
        
        let mainStack = UIStackView(arrangedSubviews: [
            headerStack,
            cardView,
            loginButton,
            forgorPasswordButton
        ])
        
        mainStack.axis = .vertical
        mainStack.spacing = 18
        mainStack.alignment = .fill
        
        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 60),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])
        
        emailStack.heightAnchor.constraint(equalToConstant: 44).isActive = true
        passwordStack.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    func showEmailError(_ text: String?) {
        emailErrorLabel.text = text
        emailErrorLabel.isHidden = (text == nil)
    }
    func showPasswordError(_ text: String?){
        passwordErrorLabel.text = text
        passwordErrorLabel.isHidden = (text == nil)
    }
    func setLoginEnabled(_ enabled: Bool){
        loginButton.isEnabled = enabled
        loginButton.alpha = enabled ? 1.0 : 0.6
    }
    
}

