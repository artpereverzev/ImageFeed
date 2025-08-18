//
//  ProfileService.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 04.08.2025.
//

import Foundation

// MARK: - ProfileResult (API Response Model)
struct ProfileResult: Codable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

// MARK: - Profile (UI Model)
struct Profile {
    let username: String
    let name: String       // Combined first and last name
    let loginName: String  // @username format
    let bio: String?
    
    init(from result: ProfileResult) {
        self.username = result.username
        
        // Combine first and last name, handling nil values
        let firstName = result.firstName ?? ""
        let lastName = result.lastName ?? ""
        self.name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        self.loginName = "@\(result.username)"
        self.bio = result.bio
    }
}

// MARK: - ProfileService
final class ProfileService {
    // MARK: - Properties
    static let shared = ProfileService()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private(set) var profile: Profile?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        // Cancel any ongoing request
        task?.cancel()
        
        guard let request = makeProfileRequest(token: token) else {
            print("[ProfileService] - Failed to create request")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        print("[ProfileService] - Fetching profile data")
        
        task = urlSession.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.task = nil
                
                switch result {
                case .success(let profileResult):
                    let profile = Profile(from: profileResult)
                    self.profile = profile
                    
                    print("[ProfileService] - Profile fetched successfully: @\(profile.username)")
                    completion(.success(profile))
                    
                case .failure(let error):
                    print("[ProfileService] - Request failed: \(error)")
                    completion(.failure(error))
                }
            }
        }
        
        task?.resume()
    }
    
    // MARK: - Private Methods
    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "/me", relativeTo: Constants.defaultBaseURL) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
}

// MARK: - ProfileService Extension
extension ProfileService {
    /// Clears the cached profile data
    /// Used during logout to reset the service state
    func reset() {
        profile = nil
        task?.cancel()
        task = nil
    }
}
