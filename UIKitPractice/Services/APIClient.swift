//
//  APIClient.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 09.12.2025.
//

import Foundation

private struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T
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

        return URL(string: "http://localhost:5000/api")!
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let url = makeURL(endpoint: endpoint)
        print("🔹 API Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ API Request error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔹 Response status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                let err = NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])
                completion(.failure(err))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                print("❌ JSON decode error: \(error.localizedDescription)")
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("🔹 Response body: \(responseStr)")
                }
                completion(.failure(error))
            }
        }.resume()
    }

    func requestEnvelope<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let url = makeURL(endpoint: endpoint)
        print("🔹 API Request URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ API Request error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("🔹 Response status code: \(statusCode)")

            guard let data else {
                completion(.failure(APIError.noData))
                return
            }

            guard (200...299).contains(statusCode) else {
                completion(.failure(self.makeError(from: data, statusCode: statusCode)))
                return
            }

            do {
                let envelope = try JSONDecoder().decode(APIEnvelope<T>.self, from: data)
                completion(.success(envelope.data))
            } catch {
                print("❌ JSON decode error: \(error.localizedDescription)")
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("🔹 Response body: \(responseStr)")
                }
                completion(.failure(APIError.decoding))
            }
        }.resume()
    }

    private func makeURL(endpoint: String) -> URL {
        let trimmedEndpoint = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var baseString = resolvedBaseURL.absoluteString
        if !baseString.hasSuffix("/") {
            baseString += "/"
        }
        let baseURL = URL(string: baseString)!
        return URL(string: trimmedEndpoint, relativeTo: baseURL)!.absoluteURL
    }

    private func makeError(from data: Data, statusCode: Int) -> Error {
        if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data),
           let message = envelope.error,
           !message.isEmpty {
            return NSError(domain: "APIClient", code: statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        switch statusCode {
        case 401: return APIError.unauthorized
        case 404: return APIError.notFound
        case 500...599: return APIError.server
        default: return APIError.unknown
        }
    }
}
