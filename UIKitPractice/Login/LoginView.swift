//
//  LoginView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 21.11.2025.
//

import UIKit
import LocalAuthentication

final class LoginView: UIView {

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    let loginTypeSegmented = UISegmentedControl(items: ["Email", "Телефон"])

    let loginField = UITextField()
    let passwordField = UITextField()

    let loginButton = UIButton(type: .system)
    let biometryButton = UIButton(type: .system)
    let forgotPasswordButton = UIButton(type: .system)

    private let logoImageView = UIImageView()
    private let errorLabel = UILabel()
    private let loginGradientLayer = CAGradientLayer()

    private(set) var loginType: LoginType = .email

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        applyLoginGradient()
        updateLoginField()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    private func setupUI() {
        backgroundColor = .systemBackground

        logoImageView.image = UIImage(systemName: "cube.fill")
        logoImageView.tintColor = .systemBlue
        logoImageView.contentMode = .scaleAspectFit

        titleLabel.text = "InventiX"
        titleLabel.font = .systemFont(ofSize: 36, weight: .bold)
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Система учёта товаров"
        subtitleLabel.font = .systemFont(ofSize: 18)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center

        loginTypeSegmented.selectedSegmentIndex = 0
        loginTypeSegmented.addTarget(self, action: #selector(loginTypeChanged), for: .valueChanged)

        setupTextField(loginField)
        setupTextField(passwordField)
        passwordField.isSecureTextEntry = true
        setupPasswordVisibilityToggle()

        errorLabel.textColor = AppColors.error
        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        loginButton.configuration = makeFilledButtonConfiguration(
            title: "Войти",
            foregroundColor: .white,
            fontSize: 18,
            fontWeight: .semibold
        )
        loginButton.heightAnchor.constraint(equalToConstant: 60).isActive = true

        biometryButton.configuration = makeFilledButtonConfiguration(
            title: "Войти с Face ID / Touch ID",
            foregroundColor: .label,
            fontSize: 16,
            fontWeight: .medium,
            imageName: "faceid"
        )
        biometryButton.heightAnchor.constraint(equalToConstant: 60).isActive = true

        forgotPasswordButton.configuration = .plain()
        forgotPasswordButton.configuration?.title = "Забыли пароль?"

        let headerStack = UIStackView(arrangedSubviews: [
            logoImageView, titleLabel, subtitleLabel
        ])
        headerStack.axis = .vertical
        headerStack.spacing = 12
        headerStack.alignment = .center

        let fieldsStack = UIStackView(arrangedSubviews: [
            loginTypeSegmented,
            loginField,
            passwordField
        ])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 12

        let mainStack = UIStackView(arrangedSubviews: [
            headerStack,
            fieldsStack,
            errorLabel,
            loginButton,
            biometryButton,
            forgotPasswordButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            logoImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    // MARK: - Logic

    @objc private func loginTypeChanged() {
        loginType = loginTypeSegmented.selectedSegmentIndex == 0 ? .email : .phone
        updateLoginField()
        clearError()
    }

    private func updateLoginField() {
        switch loginType {
        case .email:
            loginField.placeholder = "Email"
            loginField.keyboardType = .emailAddress
            loginField.leftView = createIconView(iconName: "envelope")
        case .phone:
            loginField.placeholder = "Номер телефона"
            loginField.keyboardType = .phonePad
            loginField.leftView = createIconView(iconName: "phone")
        }
    }

    // MARK: - Error

    func showError(message: String, on field: UITextField) {
        errorLabel.text = message
        errorLabel.isHidden = false
        field.layer.borderColor = AppColors.error.cgColor
        field.shake()
    }

    func clearError() {
        errorLabel.isHidden = true
        [loginField, passwordField].forEach {
            $0.layer.borderColor = AppColors.fieldBorder.cgColor
        }
    }

    // MARK: - Helpers

    private func setupTextField(_ textField: UITextField) {
        textField.backgroundColor = AppColors.fieldBackground
        textField.layer.cornerRadius = 14
        textField.layer.borderWidth = 1
        textField.layer.borderColor = AppColors.fieldBorder.cgColor
        textField.autocapitalizationType = .none
        textField.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }

    private func createIconView(iconName: String) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .secondaryLabel
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 24))
        icon.center = container.center
        container.addSubview(icon)
        return container
    }

    private func setupPasswordVisibilityToggle() {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.addTarget(self, action: #selector(togglePassword), for: .touchUpInside)
        passwordField.rightView = button
        passwordField.rightViewMode = .always
    }

    @objc private func togglePassword() {
        passwordField.isSecureTextEntry.toggle()
    }

    private func makeFilledButtonConfiguration(
        title: String,
        foregroundColor: UIColor,
        fontSize: CGFloat,
        fontWeight: UIFont.Weight,
        imageName: String? = nil
    ) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = foregroundColor
        config.titleTextAttributesTransformer = .init {
            var a = $0
            a.font = .systemFont(ofSize: fontSize, weight: fontWeight)
            return a
        }
        if let imageName {
            config.image = UIImage(systemName: imageName)
            config.imagePadding = 12
        }
        return config
    }

    private func applyLoginGradient() {
        loginGradientLayer.colors = [
            AppColors.gradientStart.cgColor,
            AppColors.gradientEnd.cgColor
        ]
        loginButton.layer.insertSublayer(loginGradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        loginGradientLayer.frame = loginButton.bounds
    }
}

// MARK: - Colors

private enum AppColors {
    static let fieldBackground = UIColor.secondarySystemBackground
    static let fieldBorder = UIColor.separator
    static let error = UIColor.systemRed
    static let gradientStart = UIColor.systemBlue
    static let gradientEnd = UIColor.systemIndigo
}
