//
//  ProductsService.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 25.01.2026.
//

import Foundation

final class ProductsService {
    
    func fetchProducts(
        category: String? = nil,
        searchQuery: String? = nil,
        completion: @escaping (Result<ProductsResponse, Error>) -> Void
    ) {
        var endpoint = "products"
        var queryItems: [String] = []
        
        if let category = category, category != "all" {
            queryItems.append("category=\(category)")
        }
        
        if let search = searchQuery, !search.isEmpty {
            queryItems.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)")
        }
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        APIClient.shared.request(
            endpoint: endpoint,
            method: "GET"
        ) { (result: Result<ProductsResponse, Error>) in
            completion(result)
        }
    }
}
