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
        print("[OAuth2Service] - Starting token fetch with code: \(code.prefix(10))...")
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            let error = NetworkError.invalidRequest
            print("[OAuth2Service] - Invalid request: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        let task = URLSession.shared.performDataTask(for: request) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                print("[OAuth2Service] - Received response data: \(data.count) bytes")
                
                // Log response as string for debugging
                if let responseString = String(data: data, encoding: String.Encoding.utf8) {
                    print("[OAuth2Service] - Response body: \(responseString)")
                }
                
                do {
                    let decoder = JSONDecoder()
                    let responseBody = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    
                    // Saving token
                    OAuth2TokenStorage.shared.token = responseBody.accessToken
                    print("[OAuth2Service] - Successfully received and saved token")
                    
                    DispatchQueue.main.async {
                        completion(.success(responseBody.accessToken))
                    }
                } catch {
                    print("[OAuth2Service] - Decoding error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("[OAuth2Service] - Detailed decoding error: \(decodingError)")
                    }
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.decodingError(error)))
                    }
                }
            case .failure(let error):
                print("[OAuth2Service] - Network error: \(error.localizedDescription)")
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .httpStatusCode(let statusCode):
                        print("[OAuth2Service] - HTTP Status Code: \(statusCode)")
                    default:
                        break
                    }
                }
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}
