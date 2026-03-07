//
//  WelcomeViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 19.11.2025.
//

import Foundation

final class WelcomeViewModel {

    var onLogin: (() -> Void)?
    
    func loginTapped() {
        print ("VM loginTapped")
        onLogin?()
    }
}

