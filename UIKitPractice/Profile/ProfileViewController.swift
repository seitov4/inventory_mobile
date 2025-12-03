//
//  ProfileViewController.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 16.11.2025.
//

import UIKit

class ProfileViewController: UIViewController, UITextFieldDelegate {
    
    // Теперь internal (по умолчанию) — extension в другом файле сможет обращаться к profileView
    let profileView = ProfileView()
    
    let viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        view = profileView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupActions()
        registerForKeyboardNotifications()
    }
    
    deinit {
        unregisterForKeyboardNotifications()
    }
    
    private func setupActions() {
        profileView.segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        profileView.switchField.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        profileView.slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        profileView.buttonField.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        profileView.logoutButton.addTarget(self, action: #selector(logoutAction), for: .touchUpInside)
        
        profileView.textField.delegate = self
        
        profileView.imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(openGallery))
        profileView.imageView.addGestureRecognizer(tap)
    }
    
    @objc func segmentChanged() {
        viewModel.segmentChanged(index: profileView.segmentControl.selectedSegmentIndex)
        profileView.textField.placeholder = viewModel.currentProfile.gender == .male ? "Введите имя (муж)" : "Введите имя (жен)"
    }
    
    @objc func switchChanged() {
        viewModel.switchChanged(isOn: profileView.switchField.isOn)
        profileView.labelField.text = profileView.switchField.isOn ? "Уведомления включены" : "Уведомления выключены"
        profileView.labelField.textColor = profileView.switchField.isOn ? .green : .red
    }
    
    @objc func sliderChanged() {
        let value = Int(profileView.slider.value)
        viewModel.sliderChanged(value: profileView.slider.value)
        profileView.label2.text = "Возраст: \(value)"
    }
    
    @objc private func logoutAction() {
        viewModel.logoutTapped()
    }
    
    @objc private func buttonTapped() {
        // 1) Завершаем текущее редактирование — это гарантирует, что textField.text актуален
        view.endEditing(true) // или profileView.textField.resignFirstResponder()
        
        // 2) Берём текст и обрезаем пробелы
        let nameTrimmed = profileView.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let age = Int(profileView.slider.value)
        
        // 3) Передаём в ViewModel (ViewModel уже делает валидацию)
        let result = viewModel.buttonTapped(name: nameTrimmed, age: age)
        showAlert(title: result.success ? "Сохранено" : "Ошибка", message: result.message)
    }

    
    @objc func openGallery() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    func unregisterForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyBoardWillShow(_ notification: Notification){
        guard let info = notification.userInfo,
              let frameValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyBoardFrame = frameValue.cgRectValue
        let keyBoardHeigh = keyBoardFrame.height
        profileView.scrollView.contentInset.bottom = keyBoardHeigh
        profileView.scrollView.verticalScrollIndicatorInsets.bottom = keyBoardHeigh
    }

    @objc func keyBoardWillHide(_ notification: Notification) {
        profileView.scrollView.contentInset.bottom = 0
        profileView.scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}
