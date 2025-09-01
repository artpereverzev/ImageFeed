//
//  AuthConfiguration.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 01.09.2025.
//
import Foundation

enum Constants {
    static let accessKey: String = "1tVjMjMFWwYAfT2RZVNiV1TtrwAyQt6in7Y4cC8vK_4"
    static let secretKey: String = "kW6IYVr7enbj4NlXC778mwVM2AnMXpihqzCYL_yEgUg"
    static let redirectURI: String = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope: String = "public+read_user+write_likes"
    static let defaultBaseURL = URL(string: "https://api.unsplash.com")!
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let defaultBaseURL: URL
    let authURLString: String
    
    init(accessKey: String, secretKey: String, redirectURI: String, accessScope: String, authURLString: String, defaultBaseURL: URL) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.redirectURI = redirectURI
        self.accessScope = accessScope
        self.defaultBaseURL = defaultBaseURL
        self.authURLString = authURLString
    }
    
    static var standard: AuthConfiguration {
        return AuthConfiguration(accessKey: Constants.accessKey,
                                secretKey: Constants.secretKey,
                                redirectURI: Constants.redirectURI,
                                accessScope: Constants.accessScope,
                                authURLString: Constants.unsplashAuthorizeURLString,
                                defaultBaseURL: Constants.defaultBaseURL)
    }
}
