//
//  ProfileImageService.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 04.08.2025.
//

import Foundation

// MARK: - UserResult (API Response Model)
struct UserResult: Codable {
    let profileImage: ProfileImage
    
    struct ProfileImage: Codable {
        let small: String
        let medium: String
        let large: String
    }
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

// MARK: - ProfileImageService
final class ProfileImageService {
    // MARK: - Properties
    static let shared = ProfileImageService()
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private(set) var avatarURL: String?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        // Cancel any ongoing request
        task?.cancel()
        
        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ProfileImageService] - No auth token available")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        guard let request = makeUserRequest(username: username, token: token) else {
            print("[ProfileImageService] - Failed to create request")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        print("[ProfileImageService] - Fetching avatar URL for user: \(username)")
        
        task = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.task = nil
                
                switch result {
                case .success(let userResult):
                    // Use 'large' instead of 'small' for better quality
                    let avatarURL = userResult.profileImage.large
                    self.avatarURL = avatarURL
                    
                    print("[ProfileImageService] - Avatar URL fetched successfully")
                    
                    // Post notification about avatar URL change
                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": avatarURL]
                    )
                    
                    completion(.success(avatarURL))
                    
                case .failure(let error):
                    print("[ProfileImageService] - Request failed: \(error)")
                    completion(.failure(error))
                }
            }
        }
        
        task?.resume()
    }
    
    // MARK: - Private Methods
    private func makeUserRequest(username: String, token: String) -> URLRequest? {
        guard let url = URL(string: "/users/\(username)", relativeTo: Constants.defaultBaseURL) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
}
