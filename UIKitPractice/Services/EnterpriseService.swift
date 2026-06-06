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
}
