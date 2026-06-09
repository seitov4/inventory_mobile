//
//  EnterpriseService.swift
//  UIKitPractice
//

import Foundation

private struct BackendUserDTO: Decodable {
    let id: Int
    let email: String?
    let phone: String?
    let firstName: String?
    let lastName: String?
    let storeName: String?
    let role: String
    let isActive: Bool?

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case firstName = "first_name"
        case lastName = "last_name"
        case storeName = "store_name"
        case role
        case isActive = "is_active"
    }

    var employee: Employee {
        let name = [firstName, lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return Employee(
            id: id,
            fullName: name.isEmpty ? (email ?? phone ?? "User #\(id)") : name,
            role: role,
            phone: phone ?? email ?? "",
            isActive: isActive ?? true
        )
    }
}

struct CreateEmployeeRequest: Encodable {
    let contact: String
    let firstName: String
    let lastName: String
    let role: String
    let password: String

    private enum CodingKeys: String, CodingKey {
        case contact
        case firstName
        case lastName
        case role
        case password
    }
}

private struct CreatedUserDTO: Decodable {
    let user: BackendUserDTO

    private enum CodingKeys: String, CodingKey {
        case user
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let user = try? container.decode(BackendUserDTO.self, forKey: .user) {
            self.user = user
        } else {
            self.user = try BackendUserDTO(from: decoder)
        }
    }
}

final class EnterpriseService {
    static let shared = EnterpriseService()

    private init() {}

    func fetchEnterprise(completion: @escaping (Result<(EnterpriseInfo, [Employee]), Error>) -> Void) {
        AuthService.shared.getCurrentUser { userResult in
            switch userResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let user):
                APIClient.shared.requestEnvelope(endpoint: "users") { (employeesResult: Result<[BackendUserDTO], Error>) in
                    switch employeesResult {
                    case .success(let users):
                        let enterprise = EnterpriseInfo(
                            name: user.store_name ?? users.first?.storeName ?? "InventiX",
                            address: L10n.tr("enterprise.address_unavailable"),
                            phone: user.phone ?? "",
                            email: user.email ?? "",
                            taxId: L10n.tr("enterprise.tax_id_unavailable")
                        )
                        completion(.success((enterprise, users.map(\.employee))))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func createEmployee(
        request: CreateEmployeeRequest,
        completion: @escaping (Result<Employee, Error>) -> Void
    ) {
        guard let data = try? JSONEncoder().encode(request) else {
            completion(.failure(AppError.unknown))
            return
        }

        APIClient.shared.requestEnvelope(
            endpoint: "users",
            method: "POST",
            body: data
        ) { (result: Result<CreatedUserDTO, Error>) in
            completion(result.map { $0.user.employee })
        }
    }

    func deleteEmployee(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        APIClient.shared.request(
            endpoint: "users/\(id)",
            method: "DELETE"
        ) { (result: Result<DeleteEmployeeResponse, Error>) in
            completion(result.map { _ in () })
        }
    }
}

private struct DeleteEmployeeResponse: Decodable {
    let success: Bool
    let error: String?
}
