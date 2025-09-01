//
//  AuthViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 13.07.2025.
//
import UIKit
import ProgressHUD

// MARK: - AuthViewControllerDelegate protocol for delegation
protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    // MARK: - UI Elements
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "auth_screen_logo")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Войти", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        button.backgroundColor = .white
        button.setTitleColor(.ypBlack, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "Authenticate"
        return button
    }()
    
    // MARK: - Properties
    private let oauth2Service = OAuth2Service.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    
    weak var delegate: AuthViewControllerDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        configureBackButton()
    }
    
    // MARK: - Private Methods
    private func setupViews() {
        view.backgroundColor = .ypBlack
        view.addSubview(logoImageView)
        view.addSubview(loginButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Logo
            logoImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Login Button
            loginButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .ypBlack
    }
    
    // MARK: - Actions
    @objc private func loginButtonTapped() {
        let webViewVC = WebViewViewController()
        let authHelper = AuthHelper()
        let webViewPresenter = WebViewPresenter(authHelper: authHelper)
        
        // Connect view and presenter
        webViewVC.presenter = webViewPresenter
        webViewPresenter.view = webViewVC
        webViewVC.delegate = self
        
        navigationController?.pushViewController(webViewVC, animated: true)
    }
}

// MARK: - WebView View Controller Delegate
extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        print("[AuthViewController] - Received authentication code, fetching token...")
        
        // Dismiss WebView first
        navigationController?.popViewController(animated: true)
        
        // Show blocking progress HUD after a small delay to ensure smooth animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            UIBlockingProgressHUD.show()
            self?.performAuthentication(with: code)
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        print("[AuthViewController] - User cancelled authentication")
        navigationController?.popViewController(animated: true)
    }
    
    private func performAuthentication(with code: String) {
        oauth2Service.fetchAuthToken(code: code) { [weak self] result in
            // Always dismiss the progress HUD
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else {
                print("[AuthViewController] - Self was deallocated during authentication")
                return
            }
            
            switch result {
            case .success(let token):
                print("[AuthViewController] - Authentication successful, token received: \(token.prefix(10))...")
                print("[AuthViewController] - Notifying delegate")
                self.delegate?.didAuthenticate(self)
                
            case .failure(let error):
                print("[AuthViewController] - Authentication failed: \(error.localizedDescription)")
                self.showAuthenticationError(error)
            }
        }
    }
}

// MARK: - Private Methods Extension
extension AuthViewController {
    private func showAuthenticationError(_ error: Error) {
        let alert = UIAlertController(
            title: "Что-то пошло не так :(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
