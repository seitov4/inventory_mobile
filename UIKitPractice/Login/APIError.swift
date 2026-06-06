//
//  APIError.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 17.12.2025.
//

import Foundation

enum AppError: LocalizedError {
    case network(URLError)
    case unauthorized
    case forbidden
    case notFound
    case server(statusCode: Int, message: String?)
    case decoding
    case noData
    case invalidURL
    case unknown

    var errorDescription: String? {
        switch self {
        case .network(let error):
            switch error.code {
            case .notConnectedToInternet:
                return L10n.tr("error.network_offline")
            case .timedOut:
                return L10n.tr("error.network_timeout")
            case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate:
                return L10n.tr("error.network_ssl")
            default:
                return L10n.tr("error.network_generic")
            }
        case .unauthorized:
            return L10n.tr("auth.invalid_credentials")
        case .forbidden:
            return L10n.tr("auth.forbidden")
        case .notFound:
            return L10n.tr("auth.user_not_found")
        case .server(_, let message):
            return message?.isEmpty == false ? message : L10n.tr("auth.server_unavailable")
        case .decoding:
            return L10n.tr("auth.decoding_error")
        case .noData:
            return L10n.tr("auth.no_data")
        case .invalidURL:
            return L10n.tr("error.invalid_url")
        case .unknown:
            return L10n.tr("auth.generic_error")
        }
    }

    static func map(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let urlError = error as? URLError {
            return .network(urlError)
        }

        return .unknown
    }
}

typealias APIError = AppError
