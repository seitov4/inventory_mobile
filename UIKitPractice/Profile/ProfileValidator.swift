//
//  ProfileValidator.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 18.11.2025.
//

import Foundation

struct ProfileValidator {
    
    static func isValidName(_ name: String?) -> Bool {
        guard let name = name else { return false }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
    }
    
    static func isValidAge(_ age: Int) -> Bool {
        return age >= 18
    }
}
