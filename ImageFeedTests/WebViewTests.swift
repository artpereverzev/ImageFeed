//
//  WebViewTests.swift
//  ImageFeedTests
//
//  Created by Artem Pereverzev on 01.09.2025.
//

import XCTest
@testable import ImageFeed

// MARK: - Test Doubles

final class WebViewPresenterSpy: WebViewPresenterProtocol {
    var viewDidLoadCalled = false
    var view: WebViewViewControllerProtocol?
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func didUpdateProgressValue(_ newValue: Double) {}
    
    func code(from url: URL) -> String? {
        return nil
    }
}

final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: WebViewPresenterProtocol?
    var loadRequestCalled = false
    var setProgressValueCalled = false
    var setProgressHiddenCalled = false
    
    var lastProgressValue: Float?
    var lastProgressHiddenValue: Bool?
    
    func load(request: URLRequest) {
        loadRequestCalled = true
    }
    
    func setProgressValue(_ newValue: Float) {
        setProgressValueCalled = true
        lastProgressValue = newValue
    }
    
    func setProgressHidden(_ isHidden: Bool) {
        setProgressHiddenCalled = true
        lastProgressHiddenValue = isHidden
    }
}

// MARK: - WebView Tests

final class WebViewTests: XCTestCase {
    
    // Test that view controller calls presenter's viewDidLoad
    func testViewControllerCallsViewDidLoad() {
        // Given
        let viewController = WebViewViewController()
        let presenter = WebViewPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        
        // When
        _ = viewController.view // Trigger view load
        
        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    // Test that presenter calls load request on view
    func testPresenterCallsLoadRequest() {
        // Given
        let viewSpy = WebViewViewControllerSpy()
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        presenter.view = viewSpy
        
        // When
        presenter.viewDidLoad()
        
        // Then
        XCTAssertTrue(viewSpy.loadRequestCalled)
    }
    
    // Test progress visible when less than one
    func testProgressVisibleWhenLessThanOne() {
        // Given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 0.6
        
        // When (accessing private method through protocol)
        let viewSpy = WebViewViewControllerSpy()
        presenter.view = viewSpy
        presenter.didUpdateProgressValue(Double(progress))
        
        // Then
        XCTAssertEqual(viewSpy.lastProgressValue, progress)
        XCTAssertEqual(viewSpy.lastProgressHiddenValue, false)
    }
    
    // Test progress hidden when one
    func testProgressHiddenWhenOne() {
        // Given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 1.0
        
        // When
        let viewSpy = WebViewViewControllerSpy()
        presenter.view = viewSpy
        presenter.didUpdateProgressValue(Double(progress))
        
        // Then
        XCTAssertEqual(viewSpy.lastProgressValue, progress)
        XCTAssertEqual(viewSpy.lastProgressHiddenValue, true)
    }
    
    // Test AuthHelper authURL
    func testAuthHelperAuthURL() {
        // Given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)
        
        // When
        let url = authHelper.authURL()
        
        // Then
        guard let urlString = url?.absoluteString else {
            XCTFail("Auth URL is nil")
            return
        }
        
        XCTAssertTrue(urlString.contains(configuration.authURLString))
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        XCTAssertTrue(urlString.contains(configuration.redirectURI))
        XCTAssertTrue(urlString.contains("code"))
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }
    
    // Test code extraction from URL
    func testCodeFromURL() {
        // Given
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native")!
        urlComponents.queryItems = [URLQueryItem(name: "code", value: "test code")]
        let url = urlComponents.url!
        let authHelper = AuthHelper()
        
        // When
        let code = authHelper.code(from: url)
        
        // Then
        XCTAssertEqual(code, "test code")
    }
}
