//
//  ImageFeedUITests.swift
//  ImageFeedUITests
//
//  Created by Artem Pereverzev on 01.09.2025.
//

import XCTest

final class ImageFeedUITests: XCTestCase {
    private let app = XCUIApplication()
    
    // MARK: - Setup
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // MARK: - Test Auth
    func testAuth() throws {
        // Skip test if already authenticated (for subsequent test runs)
        if app.tables.cells.count > 0 {
            return
        }
        
        // 1. Tap the authorization button
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5))
        authButton.tap()
        
        // 2. Wait for the WebView to load
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 10))
        
        // 3. Find and fill the email field
        sleep(3) // Wait for web content to load
        
        let emailField = webView.descendants(matching: .textField).element
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText("") // Add email for testing, don't forget to remove
        
        // 4. Find and fill the password field
        app.toolbars.buttons["Done"].tap() // Dismiss keyboard if present
        
        let passwordField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText("") // Add password for testing, don't forget to remove
        
        // 5. Tap the login button
        app.toolbars.buttons["Done"].tap() // Dismiss keyboard
        webView.swipeUp() // Scroll to make login button visible
        
        let loginButton = webView.buttons["Login"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        loginButton.tap()
        
        // 6. Wait for the feed to load
        let tablesQuery = app.tables
        let firstCell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 15), "Feed did not load after authentication")
    }
    
    // MARK: - Test Feed
    func testFeed() throws {
        // Ensure we're authenticated first
        authenticateIfNeeded()
        
        // 1. Wait for the feed screen to load
        let tablesQuery = app.tables
        let firstTable = tablesQuery.firstMatch
        XCTAssertTrue(firstTable.waitForExistence(timeout: 10))
        
        let firstCell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10), "First cell did not appear")
        
        // 2. Scroll the feed
        sleep(2)
        firstTable.swipeUp()
        sleep(1)
        
        // 3. Like the first cell
        let likeButton = firstCell.buttons["LikeButton"]
        if likeButton.exists {
            likeButton.tap()
            sleep(2) // Wait for like animation
        }
        
        // 4. Unlike the same cell
        if likeButton.exists {
            likeButton.tap()
            sleep(2) // Wait for unlike animation
        }
        
        // 5. Tap the first cell to open full screen image
        firstCell.tap()
        
        // 6. Wait for full screen image to load
        sleep(3)
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Full screen image did not open")
        
        // 7. Zoom in on the image
        let image = scrollView.images.firstMatch
        if image.exists {
            image.pinch(withScale: 3, velocity: 1)
            sleep(1)
            
            // 8. Zoom out
            image.pinch(withScale: 0.5, velocity: -1)
            sleep(1)
        }
        
        // 9. Return to feed
        let backButton = app.buttons["BackButton"]
        if backButton.exists {
            backButton.tap()
        } else {
            // Try alternate back button or swipe
            app.swipeDown()
        }
        
        // Verify we're back in the feed
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "Did not return to feed")
    }
    
    // MARK: - Test Profile
    func testProfile() throws {
        // Ensure we're authenticated first
        authenticateIfNeeded()
        
        // 1. Wait for feed to load
        let tablesQuery = app.tables
        let firstTable = tablesQuery.firstMatch
        XCTAssertTrue(firstTable.waitForExistence(timeout: 10))
        sleep(2)
        
        // 2. Navigate to profile tab
        let profileTab = app.tabBars.buttons.element(boundBy: 1) // Profile is second tab
        XCTAssertTrue(profileTab.exists)
        profileTab.tap()
        
        // 3. Wait for profile to load
        sleep(3)
        
        // 4. Verify profile elements exist
        // Check for name label (should contain some text)
        let nameLabel = app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH '@'"))
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 5), "Profile username not found")
        
        // 5. Find and tap logout button
        let logoutButton = app.buttons["LogoutButton"]
        if !logoutButton.exists {
            // Try to find by image
            let exitButton = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Exit'"))
            if exitButton.exists {
                exitButton.tap()
            }
        } else {
            logoutButton.tap()
        }
        
        // 6. Handle logout confirmation alert
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 3) {
            let confirmButton = alert.buttons["Да"] // "Yes" in Russian
            if !confirmButton.exists {
                // Try English version
                let yesButton = alert.buttons["Yes"]
                if yesButton.exists {
                    yesButton.tap()
                }
            } else {
                confirmButton.tap()
            }
        }
        
        // 7. Verify we're back at auth screen
        sleep(3)
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 10), "Did not return to auth screen after logout")
    }
    
    // MARK: - Helper Methods
    private func authenticateIfNeeded() {
        // Check if we need to authenticate
        let authButton = app.buttons["Authenticate"]
        if authButton.waitForExistence(timeout: 2) {
            // We're on the auth screen, need to authenticate
            print("Not authenticated, skipping test that requires authentication")
            XCTSkip("This test requires authentication. Run testAuth() first.")
        }
    }
    
    // MARK: - Additional Helper for Debugging
    private func printUIHierarchy() {
        print("=== UI Hierarchy ===")
        print(app.debugDescription)
        print("===================")
    }
}

// MARK: - UI Test Launch Tests
extension ImageFeedUITests {
    
    /// Test that the app launches successfully
    func testAppLaunch() throws {
        // Verify the app launches without crashing
        XCTAssertTrue(app.exists)
        
        // Check that either auth screen or feed is visible
        let authButton = app.buttons["Authenticate"]
        let feedTable = app.tables.firstMatch
        
        let authScreenVisible = authButton.waitForExistence(timeout: 3)
        let feedVisible = feedTable.waitForExistence(timeout: 3)
        
        XCTAssertTrue(authScreenVisible || feedVisible, "Neither auth screen nor feed is visible after launch")
    }
}
