//
//  ProfileViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import UIKit
import PhotosUI

final class ProfileViewController: UIViewController {

    let profileView = ProfileView()
    
    // MARK: - Колбэки для координатора
    var onLogout: (() -> Void)?
    var onShowSettings: (() -> Void)?
    var onShowSupport: (() -> Void)?
    var onShowEditProfile: (() -> Void)?
    var onShowProfileDetails: (() -> Void)?

    override func loadView() {
        view = profileView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Профиль"
        setupCallbacks()
        

        // TODO: заменить, когда появятся реальные данные
        profileView.configure(name: "Иван Иванов", email: "ivan@example.com")
    }

    private func setupCallbacks() {
        profileView.onEditProfile = { [weak self] in
            self?.onShowEditProfile?()
        }

        profileView.onOpenSettings = { [weak self] in
            self?.onShowSettings?()
        }

        profileView.onOpenProfileDetails = { [weak self] in
            self?.onShowProfileDetails?()
        }

        profileView.onOpenSupport = { [weak self] in
            self?.onShowSupport?()
        }

        profileView.onAvatarTapped = { [weak self] in
            self?.openPhotoLibrary()
        }

        // Logout с алертом (1 раз!)
        profileView.onLogoutTapped = { [weak self] in
            self?.showLogoutAlert()
        }
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
            title: "Выйти из аккаунта?",
            message: "Вы точно хотите выйти?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
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
                self?.profileView.headerView.updateAvatar(image: image)
            }
        }
    }
}
