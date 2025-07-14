//
//  OAuth2TokenStorage.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 14.07.2025.
//
import Foundation

final class OAuth2TokenStorage {
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "bearerToken"
    
    static let shared = OAuth2TokenStorage()
    
    var token: String? {
        get {
            userDefaults.string(forKey: tokenKey)
        }
        set {
            if let newValue = newValue {
                userDefaults.set(newValue, forKey: tokenKey)
            } else {
                userDefaults.removeObject(forKey: tokenKey)
            }
        }
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    func clearToken() {
        token = nil
    }
}
