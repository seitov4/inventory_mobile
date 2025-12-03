//
//  ProfileView.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 18.11.2025.
//

import Foundation
import UIKit

class ProfileView: UIView {
    
    let scrollView = UIScrollView()
    let contentView = UIView()
   
    let imageView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "IMG_1198")
        image.layer.cornerRadius = 50
        image.clipsToBounds = true
        image.layer.borderWidth = 2
        image.layer.borderColor = UIColor.lightGray.cgColor
        image.contentMode = .scaleAspectFill
        return image
    }()
    
    let textField: UITextField = {
        let text = UITextField()
        text.placeholder = "Введите имя"
        text.layer.cornerRadius = 8
        text.borderStyle = .roundedRect
        return text
    }()
    
    let segmentControl: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["Мужчина", "Женщина"])
        segment.selectedSegmentIndex = 0
        return segment
    }()
    
    let switchField: UISwitch = {
        let sw = UISwitch()
        sw.isOn = false
        return sw
    }()
    
    let labelField: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Включить уведомления"
        return label
    }()
    
    let buttonField: UIButton = {
        let button = UIButton()
        button.setTitle("Сохранить", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    let label2: UILabel = {
        let ageLabel = UILabel()
        ageLabel.textAlignment = .center
        ageLabel.text = "Возраст 0"
        return ageLabel
    }()
    
    let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 80
        return slider
    }()
    
    let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Выйти", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [imageView, textField, segmentControl, switchField, labelField, buttonField, label2, slider, logoutButton].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        [imageView, textField, segmentControl, switchField, labelField, buttonField, slider, label2, logoutButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            textField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 44),
            
            segmentControl.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            segmentControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            segmentControl.widthAnchor.constraint(equalToConstant: 220),
            
            switchField.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 20),
            switchField.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            labelField.topAnchor.constraint(equalTo: switchField.bottomAnchor, constant: 20),
            labelField.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            buttonField.topAnchor.constraint(equalTo: labelField.bottomAnchor, constant: 50),
            buttonField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 90),
            buttonField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -90),
            buttonField.heightAnchor.constraint(equalToConstant: 50),
            
            slider.topAnchor.constraint(equalTo: buttonField.bottomAnchor, constant: 20),
            slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            label2.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 20),
            label2.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label2.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
        
        scrollView.alwaysBounceVertical = true
        scrollView.isUserInteractionEnabled = true
        contentView.isUserInteractionEnabled = true
    }
}

