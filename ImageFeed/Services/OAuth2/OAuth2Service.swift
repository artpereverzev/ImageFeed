//
//  OAuth2Service.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 14.07.2025.
//
import Foundation

final class OAuth2Service {
    // MARK: - Properties
    static let shared = OAuth2Service()
    
    private var task: URLSessionTask?
    private var lastCode: String?
    
    private struct OAuthTokenResponseBody: Decodable {
        let accessToken: String
        let tokenType: String
        let scope: String
        let createdAt: Int
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case scope
            case createdAt = "created_at"
        }
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Private Methods
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service] - Failed to create URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Create form-encoded body
        let parameters = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        let bodyComponents = parameters.compactMap { (key: String, value: String) -> String? in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
                  let encodedValue = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
                return nil
            }
            return "\(encodedKey)=\(encodedValue)"
        }
        
        let bodyString = bodyComponents.joined(separator: "&")
        request.httpBody = bodyString.data(using: String.Encoding.utf8)
        
        print("[OAuth2Service] - Created POST request with body: \(bodyString)")
        return request
    }
    
    // MARK: - Public Methods
    func fetchAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)
        print("[OAuth2Service] - Starting token fetch with code: \(code.prefix(10))...")
        
        // Check if there's an existing task
        if task != nil {
            if lastCode != code {
                // Different code - cancel the previous request
                print("[OAuth2Service] - Cancelling previous request for different code")
                task?.cancel()
            } else {
                // Same code - reject duplicate request
                print("[OAuth2Service] - Duplicate request for same code, rejecting")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
        } else {
            // No task but same code as before - also reject
            if lastCode == code {
                print("[OAuth2Service] - Duplicate request for already processed code, rejecting")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
        }
        
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            let error = NetworkError.invalidRequest
            print("[OAuth2Service] - Invalid request: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            print("[OAuth2Service] - objectTask completed, dispatching to main thread")
            DispatchQueue.main.async {
                guard let self = self else {
                    print("[OAuth2Service] - Self is nil in completion")
                    return
                }
                
                // Clear task and code
                self.task = nil
                self.lastCode = nil
                
                switch result {
                case .success(let responseBody):
                    // Saving token
                    OAuth2TokenStorage.shared.token = responseBody.accessToken
                    print("[OAuth2Service] - Successfully received and saved token")
                    print("[OAuth2Service] - Calling completion handler with success")
                    completion(.success(responseBody.accessToken))
                    
                case .failure(let error):
                    print("[OAuth2Service] - Request failed: \(error)")
                    print("[OAuth2Service] - Calling completion handler with failure")
                    completion(.failure(error))
                }
            }
        }
        
        self.task = task
        task.resume()
    }
}
