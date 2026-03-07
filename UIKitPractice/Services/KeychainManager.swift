//
//  KeychainManager.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 09.12.2025.
//

import Foundation
import KeychainAccess

final class KeychainManager {
    static let shared = KeychainManager()
    private let keychain = Keychain(service: "com.yourapp.inventory")
    
    private let tokenKey = "authToken"
    
    func saveToken(_ token: String) {
        keychain[tokenKey] = token
    }
    
    func getToken() -> String? {
        return keychain[tokenKey]
    }
    
    func deleteToken() {
        try? keychain.remove(tokenKey)
    }
}
