//
//  ProfileModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 18.11.2025.
//

import Foundation


struct Profile: Codable {
    var name: String
    var age: Int
    var gender: Gender
    var notificationsEnabled: Bool
    
    enum Gender: String, Codable {
        case male = "Мужчина"
        case female = "Женщина"
    }
}
