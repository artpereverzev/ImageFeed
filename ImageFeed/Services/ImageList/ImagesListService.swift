//
//  ImagesListService.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 18.08.2025.
//

import Foundation
import UIKit

final class ImagesListService {
    // MARK: - Properties
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastLoadedPage: Int?
    
    private(set) var photos: [Photo] = []
    
    // Date formatter for parsing ISO8601 dates from API
    private let dateFormatter = ISO8601DateFormatter()
    
    // Track loaded photo IDs to prevent duplicates
    private var loadedPhotoIds = Set<String>()
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        
        // Skip if already loading
        guard task == nil else {
            print("[ImagesListService] - Request already in progress, skipping")
            return
        }
        
        // Calculate next page
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ImagesListService] - No auth token available")
            return
        }
        
        guard let request = makePhotosRequest(page: nextPage, perPage: 10, token: token) else {
            print("[ImagesListService] - Failed to create request")
            return
        }
        
        print("[ImagesListService] - Fetching page \(nextPage)")
        
        task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.task = nil
                
                switch result {
                case .success(let photoResults):
                    print("[ImagesListService] - Received \(photoResults.count) photos from API")
                    
                    // Filter out duplicates and convert to Photo objects using the new initializer
                    let newPhotos = photoResults.compactMap { photoResult -> Photo? in
                        // Check if we've already loaded this photo
                        guard !self.loadedPhotoIds.contains(photoResult.id) else {
                            print("[ImagesListService] - Skipping duplicate photo: \(photoResult.id)")
                            return nil
                        }
                        
                        // Add to loaded IDs set
                        self.loadedPhotoIds.insert(photoResult.id)
                        
                        // Convert to Photo using the new initializer
                        return Photo(from: photoResult, dateFormatter: self.dateFormatter)
                    }
                    
                    // Only update if we have new photos
                    if !newPhotos.isEmpty {
                        // Update photos array
                        self.photos.append(contentsOf: newPhotos)
                        
                        // Update last loaded page
                        self.lastLoadedPage = nextPage
                        
                        print("[ImagesListService] - Added \(newPhotos.count) new photos, total: \(self.photos.count)")
                        
                        // Post notification
                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self,
                            userInfo: ["photos": self.photos]
                        )
                    } else {
                        print("[ImagesListService] - No new photos to add (all duplicates)")
                    }
                    
                case .failure(let error):
                    print("[ImagesListService] - Failed to fetch photos: \(error)")
                }
            }
        }
        
        task?.resume()
    }
    
    // MARK: - Private Methods
    private func makePhotosRequest(page: Int, perPage: Int, token: String) -> URLRequest? {
        // Use base URL from Constants
        guard let url = URL(string: "/photos", relativeTo: Constants.defaultBaseURL) else {
            return nil
        }
        
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        
        guard let finalURL = urlComponents.url else {
            return nil
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    // MARK: - Like/Unlike Methods
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ImagesListService] - No auth token available for like operation")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        guard let request = makeLikeRequest(photoId: photoId, isLike: isLike, token: token) else {
            print("[ImagesListService] - Failed to create like request")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        print("[ImagesListService] - \(isLike ? "Liking" : "Unliking") photo: \(photoId)")
        
        let task = urlSession.performDataTask(for: request) { [weak self] result in
            // Ensure all updates happen on main thread
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(_):
                    // Find the index of the photo to update
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        // Get current photo
                        let photo = self.photos[index]
                        
                        // Create a new photo with toggled isLiked value using the copy helper
                        let updatedPhoto = photo.withToggledLike()
                        
                        // Replace the photo in the array
                        self.photos[index] = updatedPhoto
                        
                        print("[ImagesListService] - Successfully toggled like for photo: \(photoId), new status: \(updatedPhoto.isLiked)")
                        
                        // Post notification about the change
                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self,
                            userInfo: ["photos": self.photos]
                        )
                    }
                    
                    completion(.success(()))
                    
                case .failure(let error):
                    print("[ImagesListService] - Failed to \(isLike ? "like" : "unlike") photo: \(error)")
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    private func makeLikeRequest(photoId: String, isLike: Bool, token: String) -> URLRequest? {
        // Use base URL from Constants
        guard let url = URL(string: "/photos/\(photoId)/like", relativeTo: Constants.defaultBaseURL) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    // Method to clean/reset the service (useful for logout)
    func reset() {
        photos = []
        loadedPhotoIds.removeAll()
        lastLoadedPage = nil
        task?.cancel()
        task = nil
    }
}
