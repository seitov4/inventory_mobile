//
//  Profile+Extensions.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 18.11.2025.
//

import UIKit

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let edited = info[.editedImage] as? UIImage {
            profileView.imageView.image = edited
        } else if let original = info[.originalImage] as? UIImage {
            profileView.imageView.image = original
        }
        profileView.imageView.contentMode = .scaleAspectFill
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // showAlert оставляем в extension — он будет доступен внутри контроллера
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
