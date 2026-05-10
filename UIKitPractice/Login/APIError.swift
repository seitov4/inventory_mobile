//
//  APIError.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 17.12.2025.
//

import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case server
    case decoding
    case noData
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return L10n.tr("auth.invalid_credentials")
        case .notFound:
            return L10n.tr("auth.user_not_found")
        case .server:
            return L10n.tr("auth.server_unavailable")
        case .decoding:
            return L10n.tr("auth.decoding_error")
        case .noData:
            return L10n.tr("auth.no_data")
        case .unknown:
            return L10n.tr("auth.generic_error")
        }
    }
}
