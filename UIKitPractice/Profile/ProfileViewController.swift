//
//  ProfileViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit
import PhotosUI
import SwiftUI

final class ProfileViewController: UIViewController {

    let profileScreenViewModel = ProfileScreenViewModel()
    private var hostingController: UIHostingController<ProfileScreen>?
    
    // MARK: - Колбэки для координатора
    var onLogout: (() -> Void)?
    var onShowSettings: (() -> Void)?
    var onShowSupport: (() -> Void)?
    var onShowEditProfile: (() -> Void)?
    var onShowProfileDetails: (() -> Void)?
    var onShowEnterprise: (() -> Void)?
    var onShowPasscodeChange: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        embedProfileScreen()
    }

    private func embedProfileScreen() {
        let rootView = ProfileScreen(
            viewModel: self.profileScreenViewModel,
            onAvatarTap: { [weak self] in self?.openPhotoLibrary() },
            onEnterpriseTap: { [weak self] in self?.onShowEnterprise?() },
            onPersonalDataTap: { [weak self] in self?.onShowProfileDetails?() },
            onSettingsTap: { [weak self] in self?.onShowSettings?() },
            onChangePasswordTap: { [weak self] in self?.onShowPasscodeChange?() },
            onSupportTap: { [weak self] in self?.onShowSupport?() },
            onLogoutTap: { [weak self] in self?.showLogoutAlert() }
        )

        let hostingController = UIHostingController(rootView: rootView)
        self.hostingController = hostingController

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    // MARK: - Photo Picker
    private func openPhotoLibrary() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self

        present(picker, animated: true)
    }

    // MARK: - Logout Alert
    private func showLogoutAlert() {
        let alert = UIAlertController(
            title: L10n.tr("profile.logout_title"),
            message: L10n.tr("profile.logout_message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("common.logout"), style: .destructive) { [weak self] _ in
            self?.onLogout?()
        })

        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let item = results.first?.itemProvider,
              item.canLoadObject(ofClass: UIImage.self) else { return }

        item.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let image = image as? UIImage else { return }

            DispatchQueue.main.async {
                self?.profileScreenViewModel.updateAvatar(image)
            }
        }
    }
}
