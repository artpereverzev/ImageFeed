//
//  ImagesListPresenter.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 01.09.2025.
//

import UIKit

// MARK: - ImagesListPresenterProtocol
protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }
    var photosCount: Int { get }
    func viewDidLoad()
    func photo(at index: Int) -> Photo?
    func didScrollToLastCell()
    func didTapLike(at index: Int)
    func calculateHeight(for index: Int, tableWidth: CGFloat) -> CGFloat
}

// MARK: - ImagesListPresenter
final class ImagesListPresenter: ImagesListPresenterProtocol {
    // MARK: - Properties
    weak var view: ImagesListViewControllerProtocol?
    private let imagesListService: ImagesListService
    private var photos: [Photo] = []
    private var imagesListServiceObserver: NSObjectProtocol?
    
    var photosCount: Int {
        return photos.count
    }
    
    // MARK: - Constants
    private enum Constants {
        static let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        static let defaultRowHeight: CGFloat = 200
    }
    
    // MARK: - Initialization
    init(imagesListService: ImagesListService = .shared) {
        self.imagesListService = imagesListService
    }
    
    deinit {
        if let observer = imagesListServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    func viewDidLoad() {
        setupNotifications()
        loadFirstPage()
    }
    
    func photo(at index: Int) -> Photo? {
        guard index < photos.count else { return nil }
        return photos[index]
    }
    
    func didScrollToLastCell() {
        if photos.count > 0 {
            print("[ImagesListPresenter] - Loading next page")
            imagesListService.fetchPhotosNextPage()
        }
    }
    
    func didTapLike(at index: Int) {
        guard index < photos.count else { return }
        
        let photo = photos[index]
        view?.showLoading()
        
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.view?.hideLoading()
                
                switch result {
                case .success:
                    self.photos = self.imagesListService.photos
                    self.view?.updateLikeStatus(at: index, isLiked: self.photos[index].isLiked)
                    
                case .failure(let error):
                    print("[ImagesListPresenter] - Failed to change like status: \(error)")
                    self.view?.showLikeError()
                }
            }
        }
    }
    
    func calculateHeight(for index: Int, tableWidth: CGFloat) -> CGFloat {
        guard index < photos.count else {
            return Constants.defaultRowHeight
        }
        
        let photo = photos[index]
        let imageViewWidth = tableWidth - Constants.imageInsets.left - Constants.imageInsets.right
        let scale = imageViewWidth / photo.size.width
        return photo.size.height * scale + Constants.imageInsets.top + Constants.imageInsets.bottom
    }
    
    // MARK: - Private Methods
    private func setupNotifications() {
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePhotos()
        }
    }
    
    private func loadFirstPage() {
        imagesListService.fetchPhotosNextPage()
    }
    
    private func updatePhotos() {
        let oldCount = photos.count
        let newPhotos = imagesListService.photos
        
        guard newPhotos.count > oldCount else {
            photos = newPhotos
            return
        }
        
        photos = newPhotos
        
        let newIndexPaths = (oldCount..<newPhotos.count).map { $0 }
        view?.insertRows(at: newIndexPaths)
        
        print("[ImagesListPresenter] - Inserted \(newPhotos.count - oldCount) new photos")
    }
}
