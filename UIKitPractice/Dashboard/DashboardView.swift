//
//  DashboardView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import UIKit

final class DashboardView: UIView {
    
    let stack = UIStackView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    
    let summaryLabel = UILabel()
    let chartPlaceHolder = UIView()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init? (coder:NSCoder) {fatalError("init(coder:) has not been implemented")}
    private func setup() {
        backgroundColor = .systemBackground
        
        titleLabel.text = "Дашборд"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Краткая статистика по магазину"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        summaryLabel.text = "Продаж за сегодня: -"
        summaryLabel.font = .systemFont(ofSize: 16, weight: .medium)
        summaryLabel.textAlignment = .left
        
        chartPlaceHolder.backgroundColor = .secondarySystemBackground
        chartPlaceHolder.layer.cornerRadius = 12
        chartPlaceHolder.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            chartPlaceHolder.heightAnchor.constraint(equalToConstant: 160)
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.addArrangedSubview(summaryLabel)
        stack.addArrangedSubview(chartPlaceHolder)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}


