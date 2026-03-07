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
            return "Неверный логин или пароль"
        case .notFound:
            return "Пользователь не найден"
        case .server:
            return "Сервер временно недоступен"
        case .decoding:
            return "Ошибка обработки данных"
        case .noData:
            return "Нет данных от сервера"
        case .unknown:
            return "Произошла ошибка. Попробуйте позже"
        }
    }
}

