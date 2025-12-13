//
//  SettingsViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//
import UIKit

final class SettingsViewController: UIViewController {

    private let settingsView: SettingsView
    private let viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        self.viewModel = viewModel
        self.settingsView = SettingsView()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func loadView() { view = settingsView }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Настройки"
        // ensure current view reflects model
        settingsView.reload(withAppearance: viewModel.currentAppearanceIndex,
                            notificationsOn: viewModel.currentNotifications)
        setupCallbacks()
    }

    private func setupCallbacks() {
        // appearance: receives AppTheme.rawValue
        settingsView.onChangeAppearance = { [weak self] raw in
            guard let self = self else { return }
            self.viewModel.updateAppearance(raw)
            ThemeManager.shared.applyTheme(AppTheme(rawValue: raw) ?? .system)
        }

        settingsView.onToggleNotifications = { [weak self] isOn in
            self?.viewModel.toggleNotifications(isOn)
        }

        settingsView.onEditProfile = { [weak self] in
            // For example, open edit profile modally
            self?.openEditProfile()
        }
    }

    private func openEditProfile() {
        let vm = EditProfileViewModel(name: "Иван Иванов", email: "ivan@example.com")
        let vc = EditProfileViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }
}
