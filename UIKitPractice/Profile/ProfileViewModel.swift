//
//  ProfileViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 18.11.2025.
//

import UIKit

class ProfileViewModel {
    
    private var profile: Profile
    
    init(profile: Profile = Profile(name: "", age: 0, gender: .male, notificationsEnabled: false)) {
        self.profile = profile
    }
    
    var currentProfile: Profile {
        return profile
    }
    
    var onLogout: (() -> Void)?
    
    func logoutTapped() {
        onLogout?()
    }
    
    func segmentChanged(index: Int) {
        profile.gender = index == 0 ? .male : .female
    }
    
    func switchChanged(isOn: Bool) {
        profile.notificationsEnabled = isOn
    }
    
    func sliderChanged(value: Float) {
        profile.age = Int(value)
    }
    
    
    
    func buttonTapped(name: String?, age: Int) -> (success: Bool, message: String) {
        // используем validator (который уже тримит)
        guard ProfileValidator.isValidName(name) else {
            return (false, "Введите имя")
        }
        guard ProfileValidator.isValidAge(age) else {
            return (false, "Пользователю должно быть не менее 18 лет")
        }
        // now safe: name exists and is not empty after trimming
        let finalName = name!.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.name = finalName
        profile.age = age
        ProfileService.shared.saveProfile(profile)
        return (true, "Данные профиля обновлены")
    }
}
