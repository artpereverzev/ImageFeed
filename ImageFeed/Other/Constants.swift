//
//  Constants.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 13.07.2025.
//
import Foundation

enum Constants {
    static let accessKey: String = "1tVjMjMFWwYAfT2RZVNiV1TtrwAyQt6in7Y4cC8vK_4"
    static let secretKey: String = "kW6IYVr7enbj4NlXC778mwVM2AnMXpihqzCYL_yEgUg"
    static let redirectURI: String = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope: String = "public+read_user+write_likes"
    static let defaultBaseURL = URL(string: "https://api.unsplash.com")!
}
