//
//  ProductsViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 10.12.2025.
//

import UIKit

final class ProductsViewController: UIViewController {
    
    private let rootView = ProductsView()
    private let viewModel = ProductsViewModel()
    
    private var groupedProducts: [(category: String, products: [Product])] = []
    private var categories: [Category] = []
    private var selectedCategory: Category = .all
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        setupSearchBar()
        setupCategoryFilters()
        bindViewModel()
        viewModel.loadProducts()
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Товары"
    }
    
    private func setupTableView() {
        rootView.tableView.delegate = self
        rootView.tableView.dataSource = self
        rootView.tableView.register(ProductCell.self, forCellReuseIdentifier: "ProductCell")
    }
    
    private func setupSearchBar() {
        rootView.searchBar.delegate = self
    }
    
    private func setupCategoryFilters() {
        // Category buttons will be set up dynamically
    }
    
    private func bindViewModel() {
        viewModel.onProductsLoaded = { [weak self] products, stats in
            guard let self = self else { return }
            self.groupedProducts = self.viewModel.getProductsGroupedByCategory()
            self.rootView.tableView.reloadData()
            
            if let stats = stats {
                self.rootView.updateStats(
                    total: stats.totalProducts,
                    lowStock: stats.lowStockCount,
                    value: stats.formattedValue
                )
            }
        }
        
        viewModel.onCategoriesLoaded = { [weak self] categories in
            guard let self = self else { return }
            self.categories = categories
            self.rootView.updateCategories(categories, selectedCategory: self.selectedCategory)
            self.setupCategoryButtonActions()
        }
        
        viewModel.onError = { [weak self] message in
            guard let self = self else { return }
            self.showAlert(title: "Ошибка", message: message)
        }
        
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            // Можно добавить индикатор загрузки
        }
    }
    
    private func setupCategoryButtonActions() {
        rootView.categoryStackView.arrangedSubviews.enumerated().forEach { index, view in
            guard let button = view as? CategoryFilterButton else { return }
            button.tag = index
            button.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
        }
    }
    
    @objc private func categoryButtonTapped(_ sender: CategoryFilterButton) {
        let category = categories[sender.tag]
        selectedCategory = category
        viewModel.selectCategory(category)
        rootView.updateCategories(categories, selectedCategory: selectedCategory)
        setupCategoryButtonActions()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ProductsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return groupedProducts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedProducts[section].products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! ProductCell
        let product = groupedProducts[indexPath.section].products[indexPath.row]
        cell.configure(with: product)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ProductsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: Navigate to product details
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = groupedProducts[section].category + " (\(groupedProducts[section].products.count))"
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -4)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
}

// MARK: - UISearchBarDelegate

extension ProductsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.search(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - ProductCell

final class ProductCell: UITableViewCell {
    private let containerView = UIView()
    private let iconView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let quantityView = UIView()
    private let quantityLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowRadius = 2
        containerView.layer.shadowOpacity = 0.1
        
        iconView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) // Светло-серый фон для иконки
        iconView.layer.cornerRadius = 24
        iconImageView.image = UIImage(systemName: "cube.fill")
        iconImageView.tintColor = .label
        iconImageView.contentMode = .scaleAspectFit
        
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        
        quantityView.layer.cornerRadius = 16
        
        quantityLabel.font = .systemFont(ofSize: 16, weight: .bold)
        quantityLabel.textColor = .label
        quantityLabel.textAlignment = .center
        
        [containerView, iconView, iconImageView, nameLabel, subtitleLabel, quantityView, quantityLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        iconView.addSubview(iconImageView)
        quantityView.addSubview(quantityLabel)
        containerView.addSubview(iconView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(quantityView)
        contentView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: quantityView.leadingAnchor, constant: -12),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: quantityView.leadingAnchor, constant: -12),
            
            quantityView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            quantityView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            quantityView.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            quantityView.heightAnchor.constraint(equalToConstant: 24),
            
            quantityLabel.leadingAnchor.constraint(equalTo: quantityView.leadingAnchor, constant: 8),
            quantityLabel.trailingAnchor.constraint(equalTo: quantityView.trailingAnchor, constant: -8),
            quantityLabel.centerYAnchor.constraint(equalTo: quantityView.centerYAnchor)
        ])
        
        accessoryType = .disclosureIndicator
    }
    
    func configure(with product: Product) {
        nameLabel.text = product.name
        subtitleLabel.text = product.displaySubtitle
        
        if product.isLowStock {
            quantityView.backgroundColor = UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0) // #FFA500
            quantityLabel.text = "\(product.quantity)"
            quantityLabel.textColor = .label
        } else {
            quantityView.backgroundColor = UIColor(red: 0.44, green: 0.81, blue: 0.59, alpha: 1.0) // #6FCF97
            quantityLabel.text = "\(product.quantity)"
            quantityLabel.textColor = .white
        }
    }
}
