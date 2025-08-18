//
//  ProfileLogoutService.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 18.08.2025.
//

import Foundation
import WebKit
import Kingfisher

final class ProfileLogoutService {
    // MARK: - Properties
    static let shared = ProfileLogoutService()
    
    // MARK: - Initialization
    private init() { }
    
    // MARK: - Public Methods
    func logout() {
        // Clear all stored data
        cleanCookies()
        cleanToken()
        cleanServices()
        cleanImageCache()
    }
    
    // MARK: - Private Methods
    private func cleanCookies() {
        // Clear all cookies from HTTP cookie storage
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        // Clear WKWebView website data (cookies, cache, local storage, etc.)
        WKWebsiteDataStore.default().fetchDataRecords(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()
        ) { records in
            // Remove all fetched records
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(
                    ofTypes: record.dataTypes,
                    for: [record],
                    completionHandler: {}
                )
            }
        }
    }
    
    private func cleanToken() {
        // Clear the OAuth token from keychain
        OAuth2TokenStorage.shared.clearToken()
    }
    
    private func cleanServices() {
        // Reset ProfileService - clear cached profile data
        ProfileService.shared.reset()
        
        // Reset ProfileImageService - clear cached avatar URL
        ProfileImageService.shared.reset()
        
        // Reset ImagesListService - clear photos array and reset state
        ImagesListService.shared.reset()
    }
    
    private func cleanImageCache() {
        // Clear Kingfisher image cache
        // This ensures no cached images remain after logout
        let cache = ImageCache.default
        cache.clearMemoryCache()
        cache.clearDiskCache {
            print("[ProfileLogoutService] - Image cache cleared")
        }
    }
}
