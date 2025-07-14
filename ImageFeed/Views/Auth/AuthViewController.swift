//
//  AuthViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 13.07.2025.
//
import UIKit

// MARK: - AuthViewControllerDelegate protocol for delegation
protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    // MARK: - Properties
    private let webViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    
    weak var delegate: AuthViewControllerDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == webViewSegueIdentifier {
            guard let webViewViewController = segue.destination as? WebViewViewController else {
                print("[AuthViewController] - Failed to prepare for \(webViewSegueIdentifier)")
                assertionFailure("Failed to prepare for \(webViewSegueIdentifier)")
                return
            }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // MARK: - Private Methods
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .ypBlack
    }
}

// MARK: - WebView View Controller Delegate
extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        print("[AuthViewController] - Received authentication code, fetching token...")
        
        fetchAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let token):
                print("[AuthViewController] - Authentication successful, token received: \(token.prefix(10))...")
                
                // First dismiss the WebView, then notify delegate
                vc.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    print("[AuthViewController] - WebView dismissed, notifying delegate")
                    self.delegate?.didAuthenticate(self)
                }
                
            case .failure(let error):
                print("[AuthViewController] - Authentication failed: \(error.localizedDescription)")
                vc.dismiss(animated: true)
                // Here you could show an error alert to the user
                self.showAuthenticationError(error)
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        print("[AuthViewController] - User cancelled authentication")
        vc.dismiss(animated: true)
    }
}

// MARK: - Private Methods Extension
extension AuthViewController {
    private func fetchAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        oauth2Service.fetchAuthToken(code: code) { result in
            completion(result)
        }
    }
    
    private func showAuthenticationError(_ error: Error) {
        let alert = UIAlertController(
            title: "Authentication Error",
            message: "Failed to authenticate. Please try again.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
