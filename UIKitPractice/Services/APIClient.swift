//
//  APIClient.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 09.12.2025.
//

import Foundation

private struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

private struct APIErrorEnvelope: Decodable {
    let success: Bool?
    let data: String?
    let error: String?
}

final class APIClient {
    static let shared = APIClient()

    private init() {}

    private var resolvedBaseURL: URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: value) {
            return url
        }

        return AppConfig.apiBaseURL
    }

    func request<T: Decodable, Body: Encodable>(
        endpoint: String,
        method: String = "GET",
        body: Body? = nil
    ) async throws -> T {
        do {
            let encodedBody = try body.map { try JSONEncoder().encode($0) }
            return try await request(endpoint: endpoint, method: method, body: encodedBody)
        } catch {
            throw AppError.map(error)
        }
    }

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        guard let request = makeRequest(endpoint: endpoint, method: method, body: body) else {
            throw AppError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AppError.map(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.unknown
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw makeError(from: data, statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ JSON decode error: \(error.localizedDescription)")
            throw AppError.decoding
        }
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = makeURL(endpoint: endpoint) else {
            complete(completion, with: .failure(AppError.invalidURL))
            return
        }
        print("🔹 API Request URL: \(url.absoluteString)")

        let request = makeRequest(url: url, method: method, body: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ API Request error: \(error.localizedDescription)")
                self.complete(completion, with: .failure(AppError.map(error)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔹 Response status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                self.complete(completion, with: .failure(AppError.noData))
                return
            }

            if let statusCode = (response as? HTTPURLResponse)?.statusCode,
               !(200...299).contains(statusCode) {
                self.complete(completion, with: .failure(self.makeError(from: data, statusCode: statusCode)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                self.complete(completion, with: .success(decoded))
            } catch {
                print("❌ JSON decode error: \(error.localizedDescription)")
                self.complete(completion, with: .failure(AppError.decoding))
            }
        }.resume()
    }

    func requestEnvelope<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = makeURL(endpoint: endpoint) else {
            complete(completion, with: .failure(AppError.invalidURL))
            return
        }
        print("🔹 API Request URL: \(url.absoluteString)")

        let request = makeRequest(url: url, method: method, body: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ API Request error: \(error.localizedDescription)")
                self.complete(completion, with: .failure(AppError.map(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.complete(completion, with: .failure(AppError.unknown))
                return
            }

            let statusCode = httpResponse.statusCode
            print("🔹 Response status code: \(statusCode)")

            guard let data else {
                self.complete(completion, with: .failure(AppError.noData))
                return
            }

            guard (200...299).contains(statusCode) else {
                self.complete(completion, with: .failure(self.makeError(from: data, statusCode: statusCode)))
                return
            }

            do {
                let envelope = try JSONDecoder().decode(APIEnvelope<T>.self, from: data)
                guard envelope.success else {
                    self.complete(completion, with: .failure(AppError.server(statusCode: statusCode, message: envelope.error)))
                    return
                }

                guard let data = envelope.data else {
                    self.complete(completion, with: .failure(AppError.noData))
                    return
                }

                self.complete(completion, with: .success(data))
            } catch {
                print("❌ JSON decode error: \(error.localizedDescription)")
                self.complete(completion, with: .failure(AppError.decoding))
            }
        }.resume()
    }

    private func makeURL(endpoint: String) -> URL? {
        let trimmedEndpoint = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var baseString = resolvedBaseURL.absoluteString
        if !baseString.hasSuffix("/") {
            baseString += "/"
        }
        guard let baseURL = URL(string: baseString),
              let url = URL(string: trimmedEndpoint, relativeTo: baseURL) else {
            return nil
        }
        return url.absoluteURL
    }

    private func makeRequest(endpoint: String, method: String, body: Data?) -> URLRequest? {
        guard let url = makeURL(endpoint: endpoint) else { return nil }
        return makeRequest(url: url, method: method, body: body)
    }

    private func makeRequest(url: URL, method: String, body: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func makeError(from data: Data, statusCode: Int) -> Error {
        if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data),
           let message = envelope.error,
           !message.isEmpty {
            if statusCode == 401 {
                return AppError.unauthorized
            }
            return AppError.server(statusCode: statusCode, message: message)
        }

        switch statusCode {
        case 401: return AppError.unauthorized
        case 403: return AppError.forbidden
        case 404: return AppError.notFound
        case 500...599: return AppError.server(statusCode: statusCode, message: nil)
        default: return AppError.server(statusCode: statusCode, message: nil)
        }
    }

    private func complete<T>(
        _ completion: @escaping (Result<T, Error>) -> Void,
        with result: Result<T, Error>
    ) {
        let mapped: Result<T, Error> = result.mapError { AppError.map($0) as Error }
        if Thread.isMainThread {
            completion(mapped)
        } else {
            DispatchQueue.main.async {
                completion(mapped)
            }
        }
    }
}
