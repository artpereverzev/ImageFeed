//
//  ProfilePresenter.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 01.09.2025.
//

import Foundation

// MARK: - ProfilePresenterProtocol
protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogoutButton()
}

// MARK: - ProfilePresenter
final class ProfilePresenter: ProfilePresenterProtocol {
    // MARK: - Properties
    weak var view: ProfileViewControllerProtocol?
    private let profileService: ProfileService
    private let profileImageService: ProfileImageService
    private let logoutService: ProfileLogoutService
    private var profileImageServiceObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    init(profileService: ProfileService = .shared,
         profileImageService: ProfileImageService = .shared,
         logoutService: ProfileLogoutService = .shared) {
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.logoutService = logoutService
    }
    
    deinit {
        if let observer = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    func viewDidLoad() {
        setupNotificationObserver()
        updateProfileDetails()
        updateAvatar()
    }
    
    func didTapLogoutButton() {
        view?.showLogoutConfirmationAlert()
    }
    
    func confirmLogout() {
        view?.showLoading()
        logoutService.logout()
        
        // Small delay to ensure cleanup completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.view?.hideLoading()
            self?.view?.switchToSplashScreen()
        }
    }
    
    // MARK: - Private Methods
    private func setupNotificationObserver() {
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
    }
    
    private func updateProfileDetails() {
        guard let profile = profileService.profile else {
            print("[ProfilePresenter] - No profile data available")
            return
        }
        
        view?.updateProfileDetails(
            name: profile.name,
            loginName: profile.loginName,
            bio: profile.bio ?? ""
        )
        
        print("[ProfilePresenter] - Updated profile for user: \(profile.username)")
    }
    
    private func updateAvatar() {
        guard let urlString = profileImageService.avatarURL else {
            print("[ProfilePresenter] - No avatar URL available")
            return
        }
        
        view?.updateAvatar(from: urlString)
        print("[ProfilePresenter] - Avatar URL updated: \(urlString)")
    }
}
