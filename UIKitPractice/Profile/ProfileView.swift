//
//  ProfileView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit

final class ProfileView: UIView {

    // MARK: - Callbacks
    var onEditProfile: (() -> Void)?
    var onOpenProfileDetails: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenSupport: (() -> Void)?
    var onAvatarTapped: (() -> Void)?
    var onLogoutTapped: (() -> Void)?

    // MARK: - Subviews
    let headerView = ProfileHeaderView()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .systemBackground
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.delegate = self
        tv.dataSource = self
        return tv
    }()

    // КРАСИВАЯ КНОПКА ВЫХОДА — всё в одном месте и без ошибок
    private lazy var logoutButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Выйти из аккаунта"
        
        // Иконка поменьше и аккуратнее
        let icon = UIImage(systemName: "rectangle.portrait.and.arrow.right",
                           withConfiguration: UIImage.SymbolConfiguration(scale: .medium))?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        config.image = icon
        config.imagePlacement = .leading
        config.imagePadding = 6
        
        // Цвет — чуть приглушённый красный (не ядрёный systemRed)
        config.baseBackgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.3, blue: 0.28, alpha: 1.0)
                : UIColor(red: 1.0, green: 0.23, blue: 0.25, alpha: 1.0)
        }
        config.baseForegroundColor = .white
        
        // Шрифт чуть меньше и полегче
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17, weight: .medium)
            return outgoing
        }
        
        config.cornerStyle = .medium          // чуть менее скруглённая
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        
        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Тень стала мягче и ниже
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.18
        
        return button
    }()

    // MARK: - Data
    private var username: String = ""
    private var email: String?

    private let sections: [String] = ["Профиль", "Настройки", "Поддержка"]

    // MARK: - Init
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
        
        addSubview(headerView)
        addSubview(tableView)
        addSubview(logoutButton)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Анимация нажатия на кнопку
        logoutButton.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        logoutButton.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
        
        // Внутри ProfileView, в методе setupUI() — замени только этот блок констрейнтов:
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            headerView.heightAnchor.constraint(equalToConstant: 130),
            
            // TableView
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: logoutButton.topAnchor, constant: -20),
            
            // Кнопка Выйти — ГЛАВНОЕ ИСПРАВЛЕНИЕ
            logoutButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            logoutButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            logoutButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -100), // ← было -24
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Колбэки хедера
        headerView.onEditTapped = { [weak self] in self?.onEditProfile?() }
        headerView.onAvatarTapped = { [weak self] in self?.onAvatarTapped?() }
    }
    
    // MARK: - Анимации кнопки
    @objc private func buttonPressed() {
        UIView.animate(withDuration: 0.15) {
            self.logoutButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.logoutButton.alpha = 0.8
        }
    }
    
    @objc private func buttonReleased() {
        UIView.animate(
            withDuration: 0.4,
            delay: 0,                              // ← вот это было забыто!
            usingSpringWithDamping: 0.65,
            initialSpringVelocity: 0.5,
            options: .allowUserInteraction,
            animations: {
                self.logoutButton.transform = .identity
                self.logoutButton.alpha = 1.0
            },
            completion: nil
        )
    }
    
    @objc private func didTapLogout() {
        onLogoutTapped?()
    }
    
    // MARK: - Public
    func configure(name: String, email: String?) {
        username = name
        self.email = email
        headerView.configure(name: name, email: email)
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ProfileView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var content = cell.defaultContentConfiguration()
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            content.text = "Редактировать профиль"
            content.image = UIImage(systemName: "pencil")
        case (0, 1):
            content.text = "Личные данные"
            content.image = UIImage(systemName: "person.text.rectangle")
        case (1, _):
            content.text = "Настройки"
            content.image = UIImage(systemName: "gearshape")
        case (2, _):
            content.text = "Поддержка"
            content.image = UIImage(systemName: "questionmark.circle")
        default:
            break
        }
        
        content.imageProperties.tintColor = .systemGray
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0): onEditProfile?()
        case (0, 1): onOpenProfileDetails?()
        case (1, _): onOpenSettings?()
        case (2, _): onOpenSupport?()
        default: break
        }
    }
}
