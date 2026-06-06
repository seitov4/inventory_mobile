//
//  ProductsService.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 25.01.2026.
//

import Foundation

private struct BackendProductDTO: Decodable {
    let id: Int
    let name: String
    let barcode: String?
    let salePrice: Double
    let quantity: Int
    let category: String?
    let minStock: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case barcode
        case salePrice = "sale_price"
        case quantity
        case category
        case minStock = "min_stock"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        salePrice = Self.decodeDouble(from: container, forKey: .salePrice) ?? 0
        quantity = Self.decodeInt(from: container, forKey: .quantity) ?? 0
        category = try container.decodeIfPresent(String.self, forKey: .category)
        minStock = Self.decodeInt(from: container, forKey: .minStock)
    }

    private static func decodeDouble(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Double? {
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let string = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(string)
        }
        return nil
    }

    private static func decodeInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let string = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(string)
        }
        return nil
    }

    var product: Product {
        Product(
            id: id,
            name: name,
            barcode: barcode,
            price: salePrice,
            quantity: quantity,
            category: category ?? L10n.tr("products.category_uncategorized"),
            lowStockThreshold: minStock
        )
    }
}

final class ProductsService {
    
    func fetchProducts(
        category: String? = nil,
        searchQuery: String? = nil,
        completion: @escaping (Result<ProductsResponse, Error>) -> Void
    ) {
        APIClient.shared.requestEnvelope(
            endpoint: "products/left",
            method: "GET"
        ) { (result: Result<[BackendProductDTO], Error>) in
            switch result {
            case .success(let backendProducts):
                var products = backendProducts.map(\.product)

                if let category, category != "all" {
                    products = products.filter { $0.category == category }
                }

                if let searchQuery, !searchQuery.isEmpty {
                    let query = searchQuery.lowercased()
                    products = products.filter {
                        $0.name.lowercased().contains(query) ||
                        $0.category.lowercased().contains(query) ||
                        ($0.barcode?.lowercased().contains(query) ?? false)
                    }
                }

                let categories = Array(Set(backendProducts.map { $0.product.category })).sorted()
                let stats = ProductStats(
                    totalProducts: products.count,
                    lowStockCount: products.filter(\.isLowStock).count,
                    totalValue: products.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
                )
                completion(.success(ProductsResponse(
                    products: products,
                    stats: stats,
                    categories: categories
                )))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
