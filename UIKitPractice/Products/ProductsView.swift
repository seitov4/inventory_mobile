//
//  ProductsView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 10.12.2025.
//

import UIKit

final class ProductsView: UIView {
    
    // MARK: - UI Components
    
    let tableView = UITableView(frame: .zero, style: .grouped)
    let searchBar = UISearchBar()
    let categoryScrollView = UIScrollView()
    let categoryStackView = UIStackView()
    
    private let statsContainerView = UIView()
    private let statsStackView = UIStackView()
    private let statsScrollView = UIScrollView()
    
    // Stats Cards
    private let totalProductsCard = StatsCardView()
    private let lowStockCard = StatsCardView()
    private let valueCard = StatsCardView()
    private let lossesCard = StatsCardView()
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        setupStatsCards()
        setupSearchBar()
        setupCategoryFilters()
        setupTableView()
        setupConstraints()
    }
    
    private func setupStatsCards() {
        // Цвета из скриншота
        totalProductsCard.configure(
            icon: "cube.fill",
            value: "0",
            label: "Total",
            backgroundColor: UIColor(red: 0.11, green: 0.48, blue: 0.96, alpha: 0.15), // #1C7AF5 с alpha
            iconColor: UIColor(red: 0.11, green: 0.48, blue: 0.96, alpha: 1.0), // #1C7AF5
            valueColor: .label,
            labelColor: .label
        )
        
        lowStockCard.configure(
            icon: "exclamationmark.triangle.fill",
            value: "0",
            label: "Low Stock",
            backgroundColor: UIColor(red: 0.91, green: 0.98, blue: 0.89, alpha: 1.0), // #E8FAE4
            iconColor: UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0), // #FFA500
            valueColor: .label,
            labelColor: .label
        )
        
        valueCard.configure(
            icon: "chart.line.uptrend.xyaxis",
            value: "$0",
            label: "Value",
            backgroundColor: .secondarySystemBackground,
            iconColor: UIColor(red: 0.44, green: 0.81, blue: 0.59, alpha: 1.0), // #6FCF97
            valueColor: .label,
            labelColor: .label
        )
        statsScrollView.backgroundColor = .clear
        
        statsStackView.distribution = .fillEqually
        statsStackView.spacing = 12
        statsStackView.addArrangedSubview(totalProductsCard)
        statsStackView.addArrangedSubview(lowStockCard)
        statsStackView.addArrangedSubview(valueCard)
        statsStackView.addArrangedSubview(lossesCard)
        statsScrollView.addSubview(statsStackView)
        
        statsContainerView.addSubview(statsStackView)
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            statsStackView.topAnchor.constraint(equalTo: statsContainerView.topAnchor, constant: 16),
            statsStackView.leadingAnchor.constraint(equalTo: statsContainerView.leadingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: statsContainerView.trailingAnchor, constant: -16),
            statsStackView.bottomAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: -16),
            statsStackView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupSearchBar() {
        searchBar.placeholder = "Search products, categories, or barcode..."
        searchBar.searchBarStyle = .minimal
        
        // Исправление фона SearchBar согласно скриншоту
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0) // #EDEDED
        searchBar.searchTextField.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        searchBar.searchTextField.textColor = .label
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search products, categories, or barcode...",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
        searchBar.layer.cornerRadius = 12
        searchBar.clipsToBounds = true
        
        // Убираем рамку
        searchBar.searchTextField.layer.borderWidth = 0
        searchBar.searchTextField.borderStyle = .none
    }
    
    private func setupCategoryFilters() {
        categoryScrollView.showsHorizontalScrollIndicator = false
        categoryScrollView.backgroundColor = .clear
        
        categoryStackView.axis = .horizontal
        categoryStackView.spacing = 12
        categoryStackView.alignment = .center
        
        categoryScrollView.addSubview(categoryStackView)
        categoryStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            categoryStackView.topAnchor.constraint(equalTo: categoryScrollView.topAnchor),
            categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor, constant: 16),
            categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.trailingAnchor, constant: -16),
            categoryStackView.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor),
            categoryStackView.heightAnchor.constraint(equalTo: categoryScrollView.heightAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.sectionHeaderHeight = 32
    }
    
    private func setupConstraints() {
        [statsContainerView, searchBar, categoryScrollView, tableView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            statsContainerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            statsContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            statsContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            searchBar.topAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 44),
            
            categoryScrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            categoryScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 40),
            
            tableView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    func updateStats(total: Int, lowStock: Int, value: String) {
        totalProductsCard.updateValue("\(total)")
        lowStockCard.updateValue("\(lowStock)")
        valueCard.updateValue(value)
    }
    
    func updateCategories(_ categories: [Category], selectedCategory: Category) {
        categoryStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        categories.forEach { category in
            let button = CategoryFilterButton()
            button.configure(
                title: category.displayName,
                isSelected: category.name == selectedCategory.name
            )
            categoryStackView.addArrangedSubview(button)
        }
    }
}
