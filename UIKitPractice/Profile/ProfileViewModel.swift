//
//  ProfileViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import Foundation

final class ProfileViewModel {

    // MARK: - Properties
    private(set) var profile: ProfileModel

    // Callbacks to View
    var onProfileUpdated: ((ProfileModel) -> Void)?

    // MARK: - Init
    init() {
        // Load from UserDefaults or default
        let name = UserDefaults.standard.string(forKey: "profile_name") ?? "User Name"
        let email = UserDefaults.standard.string(forKey: "profile_email") ?? "user@example.com"
        let notifications = UserDefaults.standard.bool(forKey: "profile_notifications")
        let appearance = UserDefaults.standard.integer(forKey: "profile_appearance") // default 0

        profile = ProfileModel(name: name, email: email, notificationsEnabled: notifications, appearanceIndex: appearance)
    }

    // MARK: - Actions
    func updateNotifications(_ isOn: Bool) {
        profile.notificationsEnabled = isOn
        UserDefaults.standard.set(isOn, forKey: "profile_notifications")
        onProfileUpdated?(profile)
    }

    func updateAppearance(_ index: Int) {
        profile.appearanceIndex = index
        UserDefaults.standard.set(index, forKey: "profile_appearance")
        onProfileUpdated?(profile)
    }

    func logout() {
        // Clear user session / token
        print("Logout tapped")
    }

    func editProfile() {
        print("Edit profile tapped")
    }

    func changePassword() {
        print("Change password tapped")
    }

    func openSupport() {
        print("Open support tapped")
    }
}
