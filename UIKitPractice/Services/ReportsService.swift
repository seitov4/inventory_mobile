//
//  ReportsService.swift
//  UIKitPractice
//

import Foundation

struct ReportsFilterOption: Identifiable, Hashable {
    let id: String
    let title: String
    let kind: Kind

    enum Kind: Hashable {
        case all
        case product(Int)
        case category(String)
        case employee(Int)
    }
}

struct ReportsOperationOption: Identifiable, Hashable {
    let id: String
    let type: ReportOperationType
    let title: String
    let isSupported: Bool
}

struct ReportsFilters {
    let productOrCategoryOptions: [ReportsFilterOption]
    let employeeOptions: [ReportsFilterOption]
    let operationOptions: [ReportsOperationOption]
}

struct ReportsQuery {
    let from: Date
    let to: Date
    let productID: Int?
    let category: String?
    let employeeID: Int?
    let operationType: ReportOperationType?
    let limit: Int
    let offset: Int
}

struct RevenueSummary: Equatable {
    let totalRevenue: Double
    let ordersCount: Int
    let itemsSold: Int
    let averageOrderValue: Double

    static let empty = RevenueSummary(
        totalRevenue: 0,
        ordersCount: 0,
        itemsSold: 0,
        averageOrderValue: 0
    )
}

private struct ReportsFiltersDTO: Decodable {
    let products: [ReportProductDTO]
    let categories: [String]
    let employees: [ReportEmployeeDTO]
    let operationTypes: [ReportOperationTypeDTO]
}

private struct ReportProductDTO: Decodable {
    let id: Int
    let name: String
    let sku: String?
    let category: String?
}

private struct ReportEmployeeDTO: Decodable {
    let id: Int
    let name: String
    let email: String?
    let role: String
    let isActive: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case role
        case isActive = "is_active"
    }
}

private struct ReportOperationTypeDTO: Decodable {
    let value: String
    let label: String
    let supported: Bool
}

private struct ReportTransactionsDTO: Decodable {
    let transactions: [ReportTransactionDTO]
}

private struct ReportTransactionDTO: Decodable {
    let id: Int
    let date: Date
    let productID: Int
    let productName: String
    let category: String?
    let quantity: Int
    let unitPrice: Double
    let totalAmount: Double
    let employeeID: Int?
    let employeeName: String
    let employeeRole: String?
    let operationType: String
    let source: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case productID = "product_id"
        case productName = "product_name"
        case category
        case quantity
        case unitPrice = "unit_price"
        case totalAmount = "total_amount"
        case employeeID = "employee_id"
        case employeeName = "employee_name"
        case employeeRole = "employee_role"
        case operationType = "operation_type"
        case source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        let dateString = try container.decode(String.self, forKey: .date)
        date = ReportsService.isoDateFormatter.date(from: dateString) ?? Date()
        productID = try container.decode(Int.self, forKey: .productID)
        productName = try container.decode(String.self, forKey: .productName)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        quantity = Self.decodeInt(from: container, forKey: .quantity) ?? 0
        unitPrice = Self.decodeDouble(from: container, forKey: .unitPrice) ?? 0
        totalAmount = Self.decodeDouble(from: container, forKey: .totalAmount) ?? 0
        employeeID = Self.decodeInt(from: container, forKey: .employeeID)
        employeeName = try container.decode(String.self, forKey: .employeeName)
        employeeRole = try container.decodeIfPresent(String.self, forKey: .employeeRole)
        operationType = try container.decode(String.self, forKey: .operationType)
        source = try container.decodeIfPresent(String.self, forKey: .source)
    }
}

private struct RevenueDailyDTO: Decodable {
    let series: [RevenueDayDTO]
    let summary: RevenueSummaryDTO
}

private struct RevenueDayDTO: Decodable {
    let date: String
    let revenue: Double
    let ordersCount: Int
    let itemsSold: Int

    private enum CodingKeys: String, CodingKey {
        case date
        case revenue
        case ordersCount = "orders_count"
        case itemsSold = "items_sold"
    }
}

private struct RevenueSummaryDTO: Decodable {
    let totalRevenue: Double
    let ordersCount: Int
    let itemsSold: Int
    let averageOrderValue: Double

    private enum CodingKeys: String, CodingKey {
        case totalRevenue = "total_revenue"
        case ordersCount = "orders_count"
        case itemsSold = "items_sold"
        case averageOrderValue = "average_order_value"
    }
}

final class ReportsService {
    static let shared = ReportsService()

    private init() {}

    static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func fetchFilters(completion: @escaping (Result<ReportsFilters, Error>) -> Void) {
        APIClient.shared.requestEnvelope(endpoint: "reports/filters") { (result: Result<ReportsFiltersDTO, Error>) in
            switch result {
            case .success(let dto):
                let products = dto.products.map {
                    ReportsFilterOption(
                        id: "product:\($0.id)",
                        title: $0.name,
                        kind: .product($0.id)
                    )
                }
                let categories = dto.categories.map {
                    ReportsFilterOption(
                        id: "category:\($0)",
                        title: $0,
                        kind: .category($0)
                    )
                }
                let employees = dto.employees
                    .filter(\.isActive)
                    .map {
                        ReportsFilterOption(
                            id: "employee:\($0.id)",
                            title: $0.name,
                            kind: .employee($0.id)
                        )
                    }
                let operations = dto.operationTypes.compactMap { item -> ReportsOperationOption? in
                    guard let type = ReportOperationType(apiValue: item.value) else { return nil }
                    return ReportsOperationOption(
                        id: item.value,
                        type: type,
                        title: type.title,
                        isSupported: item.supported
                    )
                }

                completion(.success(ReportsFilters(
                    productOrCategoryOptions: [
                        ReportsFilterOption(id: "all", title: L10n.tr("reports.all"), kind: .all)
                    ] + products + categories,
                    employeeOptions: [
                        ReportsFilterOption(id: "all", title: L10n.tr("reports.all"), kind: .all)
                    ] + employees,
                    operationOptions: [
                        ReportsOperationOption(id: "all", type: .all, title: L10n.tr("reports.all"), isSupported: true)
                    ] + operations
                )))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchTransactions(
        query: ReportsQuery,
        completion: @escaping (Result<[ReportTransaction], Error>) -> Void
    ) {
        APIClient.shared.requestEnvelope(endpoint: endpoint("reports/transactions", query: query)) { (result: Result<ReportTransactionsDTO, Error>) in
            switch result {
            case .success(let dto):
                completion(.success(dto.transactions.map(\.transaction)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchRevenueDaily(
        query: ReportsQuery,
        completion: @escaping (Result<(summary: RevenueSummary, series: [ReportDayRevenue]), Error>) -> Void
    ) {
        APIClient.shared.requestEnvelope(endpoint: endpoint("reports/revenue-daily", query: query)) { (result: Result<RevenueDailyDTO, Error>) in
            switch result {
            case .success(let dto):
                let series = dto.series.map {
                    ReportDayRevenue(
                        id: $0.date,
                        label: Self.chartDayLabel(from: $0.date),
                        amount: $0.revenue
                    )
                }
                completion(.success((dto.summary.summary, series)))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func endpoint(_ path: String, query: ReportsQuery) -> String {
        var components = URLComponents()
        components.path = path
        components.queryItems = query.queryItems
        return components.string ?? path
    }

    private static func chartDayLabel(from value: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.localeIdentifier)
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: value) else { return value }
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

private extension ReportsQuery {
    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "from", value: Self.apiDateFormatter.string(from: from)),
            URLQueryItem(name: "to", value: Self.apiDateFormatter.string(from: to)),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]

        if let productID {
            items.append(URLQueryItem(name: "product_id", value: "\(productID)"))
        }

        if let category, !category.isEmpty {
            items.append(URLQueryItem(name: "category", value: category))
        }

        if let employeeID {
            items.append(URLQueryItem(name: "employee_id", value: "\(employeeID)"))
        }

        if let operationType, let apiValue = operationType.apiValue {
            items.append(URLQueryItem(name: "operation_type", value: apiValue))
        }

        return items
    }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private extension ReportTransactionDTO {
    var transaction: ReportTransaction {
        ReportTransaction(
            id: "\(source ?? "report")-\(id)-\(productID)",
            productName: productName,
            category: category ?? L10n.tr("products.category_uncategorized"),
            quantity: quantity,
            totalAmount: totalAmount,
            date: date,
            employeeName: employeeName,
            operationType: ReportOperationType(apiValue: operationType) ?? .sale
        )
    }
}

private extension RevenueSummaryDTO {
    var summary: RevenueSummary {
        RevenueSummary(
            totalRevenue: totalRevenue,
            ordersCount: ordersCount,
            itemsSold: itemsSold,
            averageOrderValue: averageOrderValue
        )
    }
}

private extension ReportTransactionDTO {
    private static func decodeDouble(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Double? {
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return Double(value)
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
}
