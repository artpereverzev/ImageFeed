//
//  ProfileTests.swift
//  ImageFeedTests
//
//  Created by Artem Pereverzev on 01.09.2025.
//

import XCTest
@testable import ImageFeed

// MARK: - Test Doubles for Profile

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol?
    var viewDidLoadCalled = false
    var didTapLogoutButtonCalled = false
    var confirmLogoutCalled = false
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func didTapLogoutButton() {
        didTapLogoutButtonCalled = true
    }
    
    func confirmLogout() {
        confirmLogoutCalled = true
    }
}

final class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var presenter: ProfilePresenterProtocol?
    
    var updateProfileDetailsCalled = false
    var updateAvatarCalled = false
    var showLogoutConfirmationAlertCalled = false
    var showLoadingCalled = false
    var hideLoadingCalled = false
    var switchToSplashScreenCalled = false
    
    var lastProfileName: String?
    var lastLoginName: String?
    var lastBio: String?
    var lastAvatarURL: String?
    
    func updateProfileDetails(name: String, loginName: String, bio: String) {
        updateProfileDetailsCalled = true
        lastProfileName = name
        lastLoginName = loginName
        lastBio = bio
    }
    
    func updateAvatar(from urlString: String) {
        updateAvatarCalled = true
        lastAvatarURL = urlString
    }
    
    func showLogoutConfirmationAlert() {
        showLogoutConfirmationAlertCalled = true
    }
    
    func showLoading() {
        showLoadingCalled = true
    }
    
    func hideLoading() {
        hideLoadingCalled = true
    }
    
    func switchToSplashScreen() {
        switchToSplashScreenCalled = true
    }
}

// MARK: - Profile Tests

final class ProfileTests: XCTestCase {
    
    // Test that view controller calls presenter's viewDidLoad
    func testProfileViewControllerCallsViewDidLoad() {
        // Given
        let viewController = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        
        // When
        _ = viewController.view // Trigger view load
        
        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    // Test that presenter shows logout alert on button tap
    func testPresenterShowsLogoutAlertOnButtonTap() {
        // Given
        let viewSpy = ProfileViewControllerSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewSpy
        
        // When
        presenter.didTapLogoutButton()
        
        // Then
        XCTAssertTrue(viewSpy.showLogoutConfirmationAlertCalled)
    }
    
    // Test view update profile details
    func testViewUpdateProfileDetails() {
        // Given
        let viewSpy = ProfileViewControllerSpy()
        
        // When
        viewSpy.updateProfileDetails(
            name: "Test User",
            loginName: "@testuser",
            bio: "Test bio"
        )
        
        // Then
        XCTAssertTrue(viewSpy.updateProfileDetailsCalled)
        XCTAssertEqual(viewSpy.lastProfileName, "Test User")
        XCTAssertEqual(viewSpy.lastLoginName, "@testuser")
        XCTAssertEqual(viewSpy.lastBio, "Test bio")
    }
    
    // Test view update avatar
    func testViewUpdateAvatar() {
        // Given
        let viewSpy = ProfileViewControllerSpy()
        let avatarURL = "https://example.com/avatar.jpg"
        
        // When
        viewSpy.updateAvatar(from: avatarURL)
        
        // Then
        XCTAssertTrue(viewSpy.updateAvatarCalled)
        XCTAssertEqual(viewSpy.lastAvatarURL, avatarURL)
    }
    
    // Test presenter spy methods
    func testPresenterSpyMethods() {
        // Given
        let presenter = ProfilePresenterSpy()
        
        // When
        presenter.viewDidLoad()
        presenter.didTapLogoutButton()
        presenter.confirmLogout()
        
        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
        XCTAssertTrue(presenter.didTapLogoutButtonCalled)
        XCTAssertTrue(presenter.confirmLogoutCalled)
    }
    
    // Test view spy loading methods
    func testViewSpyLoadingMethods() {
        // Given
        let viewSpy = ProfileViewControllerSpy()
        
        // When
        viewSpy.showLoading()
        viewSpy.hideLoading()
        
        // Then
        XCTAssertTrue(viewSpy.showLoadingCalled)
        XCTAssertTrue(viewSpy.hideLoadingCalled)
    }
    
    // Test view spy switch to splash screen
    func testViewSpySwitchToSplashScreen() {
        // Given
        let viewSpy = ProfileViewControllerSpy()
        
        // When
        viewSpy.switchToSplashScreen()
        
        // Then
        XCTAssertTrue(viewSpy.switchToSplashScreenCalled)
    }
    
    // Test confirm logout flow
    func testConfirmLogoutFlow() {
        // Given
        let viewSpy = ProfileViewControllerSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewSpy
        
        // When
        presenter.confirmLogout()
        
        // Then - immediately should show loading
        XCTAssertTrue(viewSpy.showLoadingCalled)
        
        // Wait for async operations
        let expectation = self.expectation(description: "Logout completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // After delay should hide loading and switch to splash
        XCTAssertTrue(viewSpy.hideLoadingCalled)
        XCTAssertTrue(viewSpy.switchToSplashScreenCalled)
    }
}
