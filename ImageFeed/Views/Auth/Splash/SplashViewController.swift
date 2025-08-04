//
//  SplashViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 14.07.2025.
//
import UIKit

final class SplashViewController: UIViewController {
    // MARK: - Properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private let storage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    
    private var wasAlreadyChecked = false
    
    // MARK: - UI Elements
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "SplashScreenLogo")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAuthenticationStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        // Set background color to match the original design
        view.backgroundColor = UIColor.ypBlack
        
        // Add logo to view hierarchy
        view.addSubview(logoImageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func checkAuthenticationStatus() {
        // Prevent multiple executions
        guard !wasAlreadyChecked else { return }
        wasAlreadyChecked = true
        
        if let token = storage.token {
            print("[SplashViewController] - Token found, fetching profile")
            fetchProfile(token: token)
        } else {
            print("[SplashViewController] - No token found, showing authentication")
            showAuthenticationScreen()
        }
    }
    
    private func showAuthenticationScreen() {
        // Create AuthViewController programmatically
        let authViewController = AuthViewController()
        authViewController.delegate = self
        
        // Create navigation controller with AuthViewController
        let navigationController = UINavigationController(rootViewController: authViewController)
        
        // Set full screen presentation style
        navigationController.modalPresentationStyle = .fullScreen
        
        // Present the navigation controller
        present(navigationController, animated: true)
    }
    
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            
            switch result {
            case .success(let profile):
                print("[SplashViewController] - Profile fetched successfully: @\(profile.username)")
                
                // Fetch avatar URL asynchronously (don't wait for it)
                self.profileImageService.fetchProfileImageURL(username: profile.username) { result in
                    switch result {
                    case .success(let avatarURL):
                        print("[SplashViewController] - Avatar URL fetched: \(avatarURL)")
                    case .failure(let error):
                        print("[SplashViewController] - Failed to fetch avatar URL: \(error)")
                    }
                }
                
                self.switchToTabBarController()
                
            case .failure(let error):
                print("[SplashViewController] - Failed to fetch profile: \(error)")
                // TODO: Handle error in Sprint 11
                // For now, just proceed to tab bar controller
                self.switchToTabBarController()
            }
        }
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            print("[SplashViewController] - Failed to get key window")
            return
        }
        
        let tabBarController = TabBarController()
        window.rootViewController = tabBarController
        
        // Add a nice transition
        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
        
        print("[SplashViewController] - Successfully switched to tab bar controller")
    }
}

// MARK: - Auth View Controller Delegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        print("[SplashViewController] - Authentication completed")
        
        guard let token = storage.token else {
            print("[SplashViewController] - No token found after authentication")
            assertionFailure("No token found after authentication")
            return
        }
        
        // Dismiss the entire navigation controller
        dismiss(animated: true) { [weak self] in
            print("[SplashViewController] - Auth screen dismissed, fetching profile with token")
            // Reset the flag only after dismiss completes
            self?.wasAlreadyChecked = false
            self?.fetchProfile(token: token)
        }
    }
}
