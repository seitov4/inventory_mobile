//
//  ProfileService.swift
//  UIKitPractice
//
//  Created by Nurseit Seitov on 18.11.2025.
//

import Foundation

class ProfileService {
    
    static let shared = ProfileService()
    
    private init () {}
    
    private let profileKey = "userDefaults"
    
    func saveProfile(_ profile: Profile){
        
        //временно сохраняем в userdefaults потом поменяем на сеть
        
        if let data = try? JSONEncoder().encode(profile){
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
    
    func loadProfile() -> Profile? {
        guard let data = UserDefaults.standard.data(forKey: profileKey),
              let profile = try? JSONDecoder().decode(Profile.self, from: data) else {
            return nil
        }
        return profile
    }
    
}
