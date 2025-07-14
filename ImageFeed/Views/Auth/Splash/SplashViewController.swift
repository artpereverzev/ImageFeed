//
//  SplashViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 14.07.2025.
//
import UIKit

final class SplashViewController: UIViewController {
    // MARK: - Properties
    override var preferredStatusBarStyle: UIStatusBarStyle {.lightContent}
    
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let storage = OAuth2TokenStorage.shared
    private var isAuthenticating = false
    
    // MARK: - Lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkAuthenticationStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - Private Methods
    private func checkAuthenticationStatus() {
        // Preventing multiple authentication flows
        guard !isAuthenticating else {
            print("[SplashViewController] - Already authenticating, skipping check")
            return
        }
        
        if let token = storage.token {
            print("[SplashViewController] - Token found: \(token.prefix(10))..., switching to tab bar")
            switchToTabBarController()
        } else {
            print("[SplashViewController] - No token found, showing authentication")
            showAuthenticationFlow()
        }
    }
    
    private func showAuthenticationFlow() {
        isAuthenticating = true
        performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
    }
    
    private func switchToTabBarController() {
        guard let window = view.window else {
            print("[SplashViewController] - Failed to get window from view")
            assertionFailure("Invalid window configuration")
            return
        }
        
        guard let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController") as? UITabBarController else {
            print("[SplashViewController] - Failed to instantiate TabBarViewController")
            assertionFailure("Failed to instantiate TabBarViewController")
            return
        }
        
        window.rootViewController = tabBarController
        print("[SplashViewController] - Successfully switched to tab bar controller")
    }
}

// MARK: - Extension for SplashViewController
extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.viewControllers[0] as? AuthViewController
            else {
                print("[SplashViewController] - Failed to prepare for \(showAuthenticationScreenSegueIdentifier)")
                assertionFailure("Failed to prepare for \(showAuthenticationScreenSegueIdentifier)")
                return
            }
            viewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - Auth View Controller Delegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        print("[SplashViewController] - Authentication completed")
        
        // Reseting authentication flag
        isAuthenticating = false
        
        // Get window reference while we still can
        guard let window = view.window else {
            print("[SplashViewController] - Failed to get window reference during authentication")
            return
        }
        
        // Create tab bar controller
        guard let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController") as? UITabBarController else {
            print("[SplashViewController] - Failed to instantiate TabBarViewController during authentication")
            return
        }
        
        // Dismiss auth flow first, then switch in completion
        vc.dismiss(animated: true) {
            print("[SplashViewController] - Auth flow dismissed, now switching to tab bar")
            window.rootViewController = tabBarController
            print("[SplashViewController] - Successfully switched to tab bar controller")
        }
    }
}
