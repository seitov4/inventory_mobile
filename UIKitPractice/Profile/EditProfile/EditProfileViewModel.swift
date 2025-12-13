//
//  EditProfileViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 06.12.2025.
//

import Foundation

final class EditProfileViewModel {

    // Данные пользователя
    var name: String
    var email: String

    // Callback при сохранении (например, чтобы координатор закрыл экран)
    var onSave: (() -> Void)?

    init(name: String, email: String) {
        self.name = name
        self.email = email
    }

    func saveChanges(name: String, email: String) {
        self.name = name
        self.email = email

        // Тут можно добавить сохранение в БД (AWS)
        print("Сохранили изменения: \(name), \(email)")
        onSave?()
    }
}
