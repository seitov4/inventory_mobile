//
//  AuthService.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 09.12.2025.
//

import Foundation

struct AuthResponse: Decodable {
    let token: String
    let user: User
}

struct User: Decodable {
    let id: Int
    let email: String?
    let phone: String?
    let first_name: String
    let last_name: String
    let store_name: String?
    let role: String
    let created_at: String
}

final class AuthService {
    
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let body = [
            "login": email,
            "password": password
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        APIClient.shared.request(endpoint: "auth/login", method: "POST", body: data) { (result: Result<AuthResponse, Error>) in
            switch result {
            case .success(let auth):
                KeychainManager.shared.saveToken(auth.token)
                completion(.success(auth.user))
            case .failure(let error):
                print("❌ Login failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func fetchCurrentUser(completion: @escaping (Result<User, Error>) -> Void) {
        APIClient.shared.request(endpoint: "auth/me") { (result: Result<AuthResponse, Error>) in
            switch result {
            case .success(let auth):
                completion(.success(auth.user))
            case .failure(let error):
                print("❌ Fetch user failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func logout() {
        KeychainManager.shared.deleteToken()
    }
}
