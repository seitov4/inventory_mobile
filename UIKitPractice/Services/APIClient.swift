//
//  APIClient.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 09.12.2025.
//

import Foundation

final class APIClient {
    static let shared = APIClient()
    
    private let baseURL = URL(string: "http://127.0.0.1:5001/api")! // <- backend URL
    private init() {}
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // Формируем полный URL
        let url = baseURL.appendingPathComponent(endpoint)
        print("🔹 API Request URL: \(url.absoluteString)") // <- печать URL для дебага
        
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
}
