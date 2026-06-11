//
//  AuthService.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 09.12.2025.
//

import Foundation

private struct AuthPayload: Decodable {
    let token: String
    let user: User
}

struct User: Decodable {
    let id: Int
    let email: String?
    let phone: String?
    let first_name: String?
    let last_name: String?
    let store_name: String?
    let role: String
    let created_at: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case first_name
        case last_name
        case store_name
        case role
        case created_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        first_name = try container.decodeIfPresent(String.self, forKey: .first_name)
        last_name = try container.decodeIfPresent(String.self, forKey: .last_name)
        store_name = try container.decodeIfPresent(String.self, forKey: .store_name)
        role = try container.decodeIfPresent(String.self, forKey: .role) ?? "cashier"
        created_at = try container.decodeIfPresent(String.self, forKey: .created_at)
    }
}

private struct LoginRequest: Encodable {
    let login: String
    let email: String?
    let password: String
}

final class AuthService {
    static let shared = AuthService()

    init() {}

    func login(
        login: String,
        password: String,
        type: LoginType,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        let request = LoginRequest(
            login: login,
            email: type == .email ? login : nil,
            password: password
        )
        guard let data = try? JSONEncoder().encode(request) else {
            completion(.failure(AppError.unknown))
            return
        }

        APIClient.shared.requestEnvelope(
            endpoint: "auth/login",
            method: "POST",
            body: data
        ) { (result: Result<AuthPayload, Error>) in
            switch result {
            case .success(let auth):
                KeychainManager.shared.saveToken(auth.token)
                UserSessionManager.shared.updateUser(id: auth.user.id, role: auth.user.role)
                completion(.success(auth.user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func logout() {
        KeychainManager.shared.deleteToken()
        UserSessionManager.shared.clear()
    }

    func getCurrentUser(completion: @escaping (Result<User, Error>) -> Void) {
        APIClient.shared.requestEnvelope(
            endpoint: "auth/me",
            method: "GET"
        ) { (result: Result<MePayload, Error>) in
            switch result {
            case .success(let payload):
                UserSessionManager.shared.updateUser(id: payload.user.id, role: payload.user.role)
                completion(.success(payload.user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private struct MePayload: Decodable {
    let user: User
}
