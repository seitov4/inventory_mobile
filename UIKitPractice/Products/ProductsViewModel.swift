//
//  ProductsViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 10.12.2025.
//

import Foundation

protocol ProductsServiceProtocol {
    func fetchProducts(
        category: String?,
        searchQuery: String?,
        completion: @escaping (Result<ProductsResponse, Error>) -> Void
    )
}

extension ProductsService: ProductsServiceProtocol {}
extension MockProductsService: ProductsServiceProtocol {}

final class ProductsViewModel {
    
    // MARK: - Callbacks
    
    var onProductsLoaded: (([Product], ProductStats?) -> Void)?
    var onCategoriesLoaded: (([Category]) -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    
    // MARK: - Properties
    
    private let productsService: ProductsServiceProtocol
    private var isMockMode: Bool = true // Флаг для переключения между mock и real
    
    private var allProducts: [Product] = []
    private var filteredProducts: [Product] = []
    private var categories: [Category] = []
    private var selectedCategory: Category = .all
    private var searchQuery: String = ""
    
    init(productsService: ProductsServiceProtocol? = nil) {
        if let service = productsService {
            self.productsService = service
            self.isMockMode = service is MockProductsService
        } else {
            self.productsService = MockProductsService()
            self.isMockMode = true
        }
    }
    
    // MARK: - Public Methods
    
    func loadProducts() {
        onLoadingStateChanged?(true)
        
        productsService.fetchProducts(
            category: selectedCategory.isAll ? nil : selectedCategory.name,
            searchQuery: searchQuery.isEmpty ? nil : searchQuery
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoadingStateChanged?(false)
                
                switch result {
                case .success(let response):
                    self?.allProducts = response.products
                    self?.categories = [.all] + response.categories.map { Category(name: $0, displayName: $0) }
                    self?.filterProducts()
                    self?.onProductsLoaded?(self?.filteredProducts ?? [], response.stats)
                    self?.onCategoriesLoaded?(self?.categories ?? [])
                    
                case .failure(let error):
                    // В mock-режиме не показываем ошибки
                    if !(self?.isMockMode ?? false) {
                        let message = (error as? APIError)?.localizedDescription ?? error.localizedDescription
                        self?.onError?(message)
                    }
                }
            }
        }
    }
    
    func selectCategory(_ category: Category) {
        selectedCategory = category
        filterProducts()
        onProductsLoaded?(filteredProducts, nil)
    }
    
    func search(_ query: String) {
        searchQuery = query
        filterProducts()
        onProductsLoaded?(filteredProducts, nil)
    }
    
    func getProductsGroupedByCategory() -> [(category: String, products: [Product])] {
        let grouped = Dictionary(grouping: filteredProducts) { $0.category }
        return grouped.sorted { $0.key < $1.key }
            .map { (category: $0.key.uppercased(), products: $0.value) }
    }
    
    // MARK: - Private Methods
    
    private func filterProducts() {
        var filtered = allProducts
        
        if !selectedCategory.isAll {
            filtered = filtered.filter { $0.category == selectedCategory.name }
        }
        
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter {
                $0.name.lowercased().contains(query) ||
                $0.category.lowercased().contains(query) ||
                ($0.barcode?.lowercased().contains(query) ?? false)
            }
        }
        
        filteredProducts = filtered
    }
}
