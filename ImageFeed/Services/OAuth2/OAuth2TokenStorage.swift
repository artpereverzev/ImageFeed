//
//  OAuth2TokenStorage.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 14.07.2025.
//
import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    // MARK: - Properties
    private let keychain = KeychainWrapper.standard
    private let tokenKey = "bearerToken"
    private let serviceName = "ImageFeedAuth"
    
    static let shared = OAuth2TokenStorage()
    
    var token: String? {
        get {
            keychain.string(
                forKey: tokenKey,
                withAccessibility: .whenUnlocked
            )
        }
        set {
            if let newValue = newValue {
                keychain.set(
                    newValue,
                    forKey: tokenKey,
                    withAccessibility: .whenUnlocked
                )
            } else {
                keychain.removeObject(forKey: tokenKey)
            }
        }
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    func clearToken() {
        token = nil
    }
    
    // Removes all keychain data for  app
    func clearAllKeychainData() {
        keychain.removeAllKeys()
    }
    
    // Check if token exists without retrieving it
    func hasToken() -> Bool {
        return keychain.hasValue(forKey: tokenKey)
    }
}
