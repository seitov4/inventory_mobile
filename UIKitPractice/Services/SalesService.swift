//
//  SalesService.swift
//  UIKitPractice
//

import Foundation

private struct BackendSaleCreateRequest: Encodable {
    let warehouseID: Int
    let items: [BackendSaleItemRequest]
    let discount: Double
    let paymentType: String

    private enum CodingKeys: String, CodingKey {
        case warehouseID = "warehouse_id"
        case items
        case discount
        case paymentType = "payment_type"
    }
}

private struct BackendSaleItemRequest: Encodable {
    let productID: Int
    let qty: Int
    let price: Double
    let discount: Double

    private enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case qty
        case price
        case discount
    }
}

private struct BackendWarehouseDTO: Decodable {
    let id: Int
}

struct SaleCreateResult: Decodable {
    let saleID: Int
    let total: String

    private enum CodingKeys: String, CodingKey {
        case saleID = "sale_id"
        case total
    }
}

private struct BackendDailySales: Decodable {
    let date: String
    let totalRevenue: Double
    let salesCount: Int
}

struct SalesChartPoint: Decodable {
    let date: String
    let total: Double
}

struct SalesChartResponse: Decodable {
    let labels: [String]
    let data: [Double]
}

final class SalesService {
    static let shared = SalesService()

    private init() {}

    func createSale(
        cartItems: [SalesCartItem],
        warehouseID: Int? = nil,
        paymentType: String = "CASH",
        completion: @escaping (Result<SaleCreateResult, Error>) -> Void
    ) {
        if let warehouseID {
            submitSale(
                cartItems: cartItems,
                warehouseID: warehouseID,
                paymentType: paymentType,
                completion: completion
            )
            return
        }

        fetchDefaultWarehouseID { [weak self] result in
            switch result {
            case .success(let warehouseID):
                self?.submitSale(
                    cartItems: cartItems,
                    warehouseID: warehouseID,
                    paymentType: paymentType,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func submitSale(
        cartItems: [SalesCartItem],
        warehouseID: Int,
        paymentType: String,
        completion: @escaping (Result<SaleCreateResult, Error>) -> Void
    ) {
        let request = BackendSaleCreateRequest(
            warehouseID: warehouseID,
            items: cartItems.map {
                BackendSaleItemRequest(
                    productID: $0.product.id,
                    qty: $0.quantity,
                    price: $0.product.price,
                    discount: 0
                )
            },
            discount: 0,
            paymentType: paymentType
        )

        guard let data = try? JSONEncoder().encode(request) else {
            completion(.failure(AppError.unknown))
            return
        }

        APIClient.shared.requestEnvelope(
            endpoint: "sales",
            method: "POST",
            body: data,
            completion: completion
        )
    }

    private func fetchDefaultWarehouseID(completion: @escaping (Result<Int, Error>) -> Void) {
        APIClient.shared.requestEnvelope(endpoint: "warehouses") { (result: Result<[BackendWarehouseDTO], Error>) in
            switch result {
            case .success(let warehouses):
                if let warehouseID = warehouses.first?.id {
                    completion(.success(warehouseID))
                } else {
                    completion(.failure(NSError(
                        domain: "SalesService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: L10n.tr("sales.no_warehouse")]
                    )))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchDailySales(completion: @escaping (Result<(revenue: Double, count: Int), Error>) -> Void) {
        APIClient.shared.requestEnvelope(endpoint: "sales/daily") { (result: Result<BackendDailySales, Error>) in
            completion(result.map { ($0.totalRevenue, $0.salesCount) })
        }
    }

    func fetchPeriodSales(
        period: AnalyticsPeriodKind,
        completion: @escaping (Result<[SalesChartPoint], Error>) -> Void
    ) {
        let endpoint: String
        switch period {
        case .week:
            endpoint = "sales/weekly"
        case .month, .quarter:
            endpoint = "sales/monthly"
        }

        APIClient.shared.requestEnvelope(endpoint: endpoint, completion: completion)
    }

    func fetchSalesChart(completion: @escaping (Result<SalesChartResponse, Error>) -> Void) {
        APIClient.shared.requestEnvelope(endpoint: "sales/chart", completion: completion)
    }
}
