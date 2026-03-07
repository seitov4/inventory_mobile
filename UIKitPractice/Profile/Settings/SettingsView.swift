//
//  SettingsView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit

final class SettingsView: UIView {

    // MARK: - Callbacks
    var onToggleNotifications: ((Bool) -> Void)?
    /// onChangeAppearance передаёт уже AppTheme.rawValue (0=system,1=light,2=dark)
    var onChangeAppearance: ((Int) -> Void)?
    var onChangePassword: (() -> Void)?
    var onEditProfile: (() -> Void)?

    // MARK: - Data
    private var currentAppearance: Int = AppTheme.system.rawValue
    private var currentNotifications: Bool = true

    // MARK: - UI Elements
    let editProfileButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Редактировать профиль", for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 18)
        return b
    }()

    private enum Section: Int, CaseIterable {
        case notifications, appearance, security
    }

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.delegate = self
        tv.dataSource = self
        tv.register(ProfileSwitchCell.self, forCellReuseIdentifier: ProfileSwitchCell.reuseIdentifier)
        tv.register(ProfileSegmentCell.self, forCellReuseIdentifier: ProfileSegmentCell.reuseIdentifier)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        return tv
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupLayout()
        setupActions()
    }

    required init?(coder: NSCoder) { super.init(coder: coder); setupLayout(); setupActions() }

    private func setupLayout() {
        addSubview(editProfileButton)
        addSubview(tableView)

        editProfileButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            editProfileButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            editProfileButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            editProfileButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            editProfileButton.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: editProfileButton.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupActions() {
        editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
    }

    @objc private func editProfileTapped() {
        onEditProfile?()
    }

    // MARK: - Public
    /// Передаём сюда AppTheme.rawValue
    func reload(withAppearance index: Int, notificationsOn: Bool) {
        self.currentAppearance = index
        self.currentNotifications = notificationsOn
        tableView.reloadData()
    }

    // mapping helpers
    private func segmentIndex(forAppearanceRaw raw: Int) -> Int {
        // ProfileSegmentCell items originally were ["Светлая","Тёмная","Системная"]
        // Мы хотим передать на сегмент порядок: [Light(0), Dark(1), System(2)] => cell expects [Light(0), Dark(1), System(2)]
        // But AppTheme.raw is [System(0), Light(1), Dark(2)]
        // So mapping AppTheme -> cellIndex:
        switch raw {
        case AppTheme.system.rawValue: return 2
        case AppTheme.light.rawValue:  return 0
        case AppTheme.dark.rawValue:   return 1
        default: return 2
        }
    }

    private func appearanceRaw(forSegmentIndex idx: Int) -> Int {
        switch idx {
        case 0: return AppTheme.light.rawValue
        case 1: return AppTheme.dark.rawValue
        case 2: return AppTheme.system.rawValue
        default: return AppTheme.system.rawValue
        }
    }
}

// MARK: - TableView
extension SettingsView: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .notifications: return "Уведомления"
        case .appearance: return "Внешний вид"
        case .security: return "Безопасность"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .notifications:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProfileSwitchCell.reuseIdentifier, for: indexPath) as! ProfileSwitchCell
            cell.configure(icon: UIImage(systemName: "bell"), title: "Уведомления", isOn: currentNotifications)
            cell.onToggle = { [weak self] isOn in self?.onToggleNotifications?(isOn) }
            return cell

        case .appearance:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProfileSegmentCell.reuseIdentifier, for: indexPath) as! ProfileSegmentCell
            let mappedIndex = segmentIndex(forAppearanceRaw: currentAppearance)
            cell.configure(icon: UIImage(systemName: "moon"), title: "Тема", selectedIndex: mappedIndex)
            cell.onSegmentChanged = { [weak self] segIdx in
                guard let self = self else { return }
                let raw = self.appearanceRaw(forSegmentIndex: segIdx)
                self.onChangeAppearance?(raw) // send AppTheme.rawValue
            }
            return cell

        case .security:
            let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "Сменить пароль"
            cfg.image = UIImage(systemName: "lock")
            cell.contentConfiguration = cfg
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if Section(rawValue: indexPath.section) == .security {
            onChangePassword?()
        }
    }
}
