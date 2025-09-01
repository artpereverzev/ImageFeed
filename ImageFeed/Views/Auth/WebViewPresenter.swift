//
//  WebViewPresenter.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 01.09.2025
//

import Foundation

// MARK: - WebViewPresenterProtocol
public protocol WebViewPresenterProtocol {
    var view: WebViewViewControllerProtocol? { get set }
    func viewDidLoad()
    func didUpdateProgressValue(_ newValue: Double)
    func code(from url: URL) -> String?
}

// MARK: - WebViewPresenter
final class WebViewPresenter: WebViewPresenterProtocol {
    // MARK: - Properties
    weak var view: WebViewViewControllerProtocol?
    var authHelper: AuthHelperProtocol
    
    // MARK: - Initialization
    init(authHelper: AuthHelperProtocol) {
        self.authHelper = authHelper
    }
    
    // MARK: - Public Methods
    func viewDidLoad() {
        guard let request = authHelper.authRequest() else {
            print("[WebViewPresenter] - Failed to create auth request")
            return
        }
        
        // Initialize progress to 0 and show the progress view
        didUpdateProgressValue(0)
        
        // Load the request in the view
        view?.load(request: request)
    }
    
    func didUpdateProgressValue(_ newValue: Double) {
        let newProgressValue = Float(newValue)
        view?.setProgressValue(newProgressValue)
        
        let shouldHideProgress = shouldHideProgress(for: newProgressValue)
        view?.setProgressHidden(shouldHideProgress)
    }
    
    func code(from url: URL) -> String? {
        authHelper.code(from: url)
    }
    
    // MARK: - Private Methods
    private func shouldHideProgress(for value: Float) -> Bool {
        abs(value - 1.0) <= 0.0001
    }
}
