//
//  LoginViewModel.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 21.11.2025.
//

import Foundation

final class LoginViewModel {

    var onLoginSuccess: (() -> Void)?
    var onValidationChanged: ((_ isEmailValid: Bool, _ isPasswordValid: Bool) -> Void)?
    
    private(set) var isEmailValid: Bool = false
    private(set) var isPasswordValid: Bool = false
    
    func validateEmail (_ email: String?){
        let text = email ?? ""
        isEmailValid = Self.isValidEmail(text)
        onValidationChanged? (isEmailValid, isPasswordValid)
    }
    
    func validatePassword (_ password: String?){
        let text = password ?? ""
        isPasswordValid = Self.isValidPassword(text)
        onValidationChanged? (isEmailValid, isPasswordValid)
    }
    

    func login(email: String?, password: String?) {
        validateEmail(email)
        validatePassword(password)
        
        guard isEmailValid && isPasswordValid else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
            self.onLoginSuccess?()
        }
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        
        let letterSet = CharacterSet.letters
        let digitSet = CharacterSet.decimalDigits
        
        if password.rangeOfCharacter(from: letterSet) == nil { return false }
        if password.rangeOfCharacter(from: digitSet) == nil { return false }
        
        return true
    }
}

