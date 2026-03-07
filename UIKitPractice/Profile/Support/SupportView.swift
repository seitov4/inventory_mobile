//
//  SupportView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit

final class SupportView: UIView {

    private let phoneNumber = "+77066260676"
    private let emailAddress = "seitov_nurseit777@mail.ru"
    private let telegramUsername = "Nurseit_Seitov"

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .systemBackground

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 28
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

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

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])

        let title = UILabel()
        title.text = "Поддержка"
        title.font = .systemFont(ofSize: 26, weight: .bold)
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Свяжитесь с нами любым удобным способом"
        subtitle.font = .systemFont(ofSize: 16)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let phoneBtn = makeContactButton(
            title: "+7 707 626 06 76",
            subtitle: "Позвонить",
            icon: "phone.fill",
            color: .systemGreen,
            action: { [weak self] in self?.callPhone() }
        )

        let emailBtn = makeContactButton(
            title: emailAddress,
            subtitle: "Написать письмо",
            icon: "envelope.fill",
            color: .systemBlue,
            action: { [weak self] in self?.sendEmail() }
        )

        let tgBtn = makeContactButton(
            title: "@\(telegramUsername)",
            subtitle: "Написать в Telegram",
            icon: "paperplane.fill",
            color: UIColor.systemIndigo,
            action: { [weak self] in self?.openTelegram() }
        )

        let info = UILabel()
        info.text = "Отвечаем быстро • 9:00–21:00 • Без выходных"
        info.font = .systemFont(ofSize: 15)
        info.textColor = .secondaryLabel
        info.textAlignment = .center
        info.numberOfLines = 0

        [title, subtitle, UIView(), phoneBtn, emailBtn, tgBtn, UIView(), info]
            .forEach(stackView.addArrangedSubview)
    }

    private func makeContactButton(
        title: String,
        subtitle: String,
        icon: String,
        color: UIColor,
        action: @escaping () -> Void
    ) -> UIButton {

        let button = ActionButton(type: .system)
        button.backgroundColor = color.withAlphaComponent(0.12)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1.5
        button.layer.borderColor = color.withAlphaComponent(0.3).cgColor

        // ⛔ Отключаем взаимодействие внутренних views
        //    чтобы касание шло ТОЛЬКО на кнопку
        button.isUserInteractionEnabled = true

        // Контейнер
        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isUserInteractionEnabled = false

        // Иконка
        let iconView = UIImageView()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        iconView.image = UIImage(systemName: icon, withConfiguration: symbolConfig)
        iconView.tintColor = color
        iconView.contentMode = .center
        iconView.isUserInteractionEnabled = false

        iconView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 30).isActive = true

        // Текст
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = color
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.isUserInteractionEnabled = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = color.withAlphaComponent(0.7)
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.isUserInteractionEnabled = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(textStack)

        button.addSubview(container)
        container.isUserInteractionEnabled = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -24),
            container.topAnchor.constraint(equalTo: button.topAnchor, constant: 16),
            container.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -16),

            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 78)
        ])

        // Анимации
        button.addTarget(self, action: #selector(btnDown), for: .touchDown)
        button.addTarget(self, action: #selector(btnUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        // Действие кнопки
        button.setAction(action)

        return button
    }


    @objc private func btnDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            sender.alpha = 0.8
        }
    }

    @objc private func btnUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .allowUserInteraction) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }

    @objc private func btnTapped(_ sender: UIButton) {
        if let action = objc_getAssociatedObject(sender, "action") as? () -> Void {
            action()
        }
    }

    private func callPhone() {
        print("📞 callPhone tapped")

        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard let url = URL(string: "tel://\(cleaned)") else { return }
        UIApplication.shared.open(url)
    }

    private func sendEmail() {
        print("📧 sendEmail tapped")

        let encoded = emailAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? emailAddress
        guard let url = URL(string: "mailto:\(encoded)") else { return }
        UIApplication.shared.open(url)
    }

    private func openTelegram() {
        print("🚀 openTelegram tapped")

        let clean = telegramUsername.replacingOccurrences(of: "@", with: "")
        let app = URL(string: "tg://resolve?domain=\(clean)")!
        let web = URL(string: "https://t.me/\(clean)")!

        print("appURL:", app)
        print("canOpen:", UIApplication.shared.canOpenURL(app))

        if UIApplication.shared.canOpenURL(app) {
            UIApplication.shared.open(app)
        } else {
            UIApplication.shared.open(web)
        }
    }

}
