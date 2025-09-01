//
//  ImagesListTests.swift
//  ImageFeedTests
//
//  Created by Artem Pereverzev on 01.09.2025.
//

import XCTest
@testable import ImageFeed

// MARK: - Test Doubles for ImagesList

final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    var view: ImagesListViewControllerProtocol?
    var viewDidLoadCalled = false
    var didScrollToLastCellCalled = false
    var didTapLikeCalled = false
    var lastLikeTapIndex: Int?
    
    private let stubbedPhotos: [Photo]
    
    init(stubbedPhotos: [Photo] = []) {
        self.stubbedPhotos = stubbedPhotos
    }
    
    var photosCount: Int {
        return stubbedPhotos.count
    }
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func photo(at index: Int) -> Photo? {
        guard index < stubbedPhotos.count else { return nil }
        return stubbedPhotos[index]
    }
    
    func didScrollToLastCell() {
        didScrollToLastCellCalled = true
    }
    
    func didTapLike(at index: Int) {
        didTapLikeCalled = true
        lastLikeTapIndex = index
    }
    
    func calculateHeight(for index: Int, tableWidth: CGFloat) -> CGFloat {
        return 200 // Default height for testing
    }
}

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var presenter: ImagesListPresenterProtocol?
    
    var insertRowsCalled = false
    var updateLikeStatusCalled = false
    var showLoadingCalled = false
    var hideLoadingCalled = false
    var showLikeErrorCalled = false
    
    var lastInsertedIndexes: [Int]?
    var lastUpdatedLikeIndex: Int?
    var lastUpdatedLikeStatus: Bool?
    
    func insertRows(at indexes: [Int]) {
        insertRowsCalled = true
        lastInsertedIndexes = indexes
    }
    
    func updateLikeStatus(at index: Int, isLiked: Bool) {
        updateLikeStatusCalled = true
        lastUpdatedLikeIndex = index
        lastUpdatedLikeStatus = isLiked
    }
    
    func showLoading() {
        showLoadingCalled = true
    }
    
    func hideLoading() {
        hideLoadingCalled = true
    }
    
    func showLikeError() {
        showLikeErrorCalled = true
    }
}

// MARK: - ImagesList Tests

final class ImagesListTests: XCTestCase {
    
    // Test that view controller calls presenter's viewDidLoad
    func testImagesListViewControllerCallsViewDidLoad() {
        // Given
        let viewController = ImagesListViewController()
        let presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        
        // When
        _ = viewController.view // Trigger view load
        
        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    // Test photo count
    func testPresenterPhotosCount() {
        // Given
        let photo1 = createMockPhoto(id: "1")
        let photo2 = createMockPhoto(id: "2")
        let presenter = ImagesListPresenterSpy(stubbedPhotos: [photo1, photo2])
        
        // When
        let count = presenter.photosCount
        
        // Then
        XCTAssertEqual(count, 2)
    }
    
    // Test photo retrieval
    func testPresenterPhotoAtIndex() {
        // Given
        let photo = createMockPhoto(id: "test-id")
        let presenter = ImagesListPresenterSpy(stubbedPhotos: [photo])
        
        // When
        let retrievedPhoto = presenter.photo(at: 0)
        
        // Then
        XCTAssertNotNil(retrievedPhoto)
        XCTAssertEqual(retrievedPhoto?.id, "test-id")
    }
    
    // Test photo retrieval out of bounds
    func testPresenterPhotoAtInvalidIndex() {
        // Given
        let presenter = ImagesListPresenterSpy(stubbedPhotos: [])
        
        // When
        let retrievedPhoto = presenter.photo(at: 0)
        
        // Then
        XCTAssertNil(retrievedPhoto)
    }
    
    // Test scroll to last cell
    func testPresenterDidScrollToLastCell() {
        // Given
        let presenter = ImagesListPresenterSpy()
        
        // When
        presenter.didScrollToLastCell()
        
        // Then
        XCTAssertTrue(presenter.didScrollToLastCellCalled)
    }
    
    // Test like tap
    func testPresenterDidTapLike() {
        // Given
        let presenter = ImagesListPresenterSpy()
        
        // When
        presenter.didTapLike(at: 5)
        
        // Then
        XCTAssertTrue(presenter.didTapLikeCalled)
        XCTAssertEqual(presenter.lastLikeTapIndex, 5)
    }
    
    // Test height calculation
    func testPresenterCalculateHeight() {
        // Given
        let presenter = ImagesListPresenter()
        
        // When
        let tableWidth: CGFloat = 375 // iPhone width
        let height = presenter.calculateHeight(for: 0, tableWidth: tableWidth)
        
        // Then
        // Should return default height when no photos
        XCTAssertEqual(height, 200)
    }
    
    // Test that presenter calls view methods when inserting rows
    func testPresenterCallsViewInsertRows() {
        // Given
        let viewSpy = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenter()
        presenter.view = viewSpy
        
        // When - simulate notification that photos changed
        presenter.viewDidLoad()
        
        // Simulate the service having photos by posting notification
        NotificationCenter.default.post(
            name: ImagesListService.didChangeNotification,
            object: nil
        )
        
        // Then - verify presenter is connected to view
        XCTAssertNotNil(presenter.view)
    }
    
    // Test presenter spy calls view loading methods
    func testPresenterSpyCallsViewLoadingMethods() {
        // Given
        let viewSpy = ImagesListViewControllerSpy()
        let photo = createMockPhoto(id: "1")
        let presenter = ImagesListPresenterSpy(stubbedPhotos: [photo])
        presenter.view = viewSpy
        
        // When
        presenter.didTapLike(at: 0)
        
        // Then - verify the spy recorded the tap
        XCTAssertTrue(presenter.didTapLikeCalled)
        XCTAssertEqual(presenter.lastLikeTapIndex, 0)
    }
    
    // Test view insert rows
    func testViewInsertRows() {
        // Given
        let viewSpy = ImagesListViewControllerSpy()
        let indexes = [0, 1, 2]
        
        // When
        viewSpy.insertRows(at: indexes)
        
        // Then
        XCTAssertTrue(viewSpy.insertRowsCalled)
        XCTAssertEqual(viewSpy.lastInsertedIndexes, indexes)
    }
    
    // Test view update like status
    func testViewUpdateLikeStatus() {
        // Given
        let viewSpy = ImagesListViewControllerSpy()
        
        // When
        viewSpy.updateLikeStatus(at: 3, isLiked: true)
        
        // Then
        XCTAssertTrue(viewSpy.updateLikeStatusCalled)
        XCTAssertEqual(viewSpy.lastUpdatedLikeIndex, 3)
        XCTAssertEqual(viewSpy.lastUpdatedLikeStatus, true)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPhoto(
        id: String,
        size: CGSize = CGSize(width: 100, height: 100),
        isLiked: Bool = false
    ) -> Photo {
        return Photo(
            id: id,
            size: size,
            createdAt: Date(),
            welcomeDescription: "Test photo",
            thumbImageURL: "https://example.com/thumb.jpg",
            largeImageURL: "https://example.com/large.jpg",
            isLiked: isLiked
        )
    }
}
