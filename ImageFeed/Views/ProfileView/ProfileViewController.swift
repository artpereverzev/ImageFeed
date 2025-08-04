//
//  ProfileViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 24.06.2025.
//
import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    // MARK: - UI Elements
    private lazy var profileAvatarImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "profile_icon_default")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 35 // Half of 70 (width/height)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.font = UIFont.boldSystemFont(ofSize: 23)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var loginNameLabel: UILabel = {
        let label = UILabel()
        label.text = "@username"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .ypLightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var logoutButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Exit"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    private var profileImageServiceObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        setupActions()
        updateProfileDetails()
        
        // Set up notification observer for avatar URL changes
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
        
        // Update avatar if already loaded
        updateAvatar()
    }
    
    deinit {
        // Clean up observer
        if let observer = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Private Methods
    private func setupView() {
        view.backgroundColor = .ypBlack
        
        view.addSubview(profileAvatarImage)
        view.addSubview(nameLabel)
        view.addSubview(loginNameLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(logoutButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Profile Avatar
            profileAvatarImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            profileAvatarImage.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            profileAvatarImage.widthAnchor.constraint(equalToConstant: 70),
            profileAvatarImage.heightAnchor.constraint(equalTo: profileAvatarImage.widthAnchor),
            
            // Logout Button
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            logoutButton.centerYAnchor.constraint(equalTo: profileAvatarImage.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: profileAvatarImage.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileAvatarImage.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            // Login Name Label
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            // Description Label
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor)
        ])
    }
    
    private func setupActions() {
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
    }
    
    private func updateProfileDetails() {
        guard let profile = profileService.profile else {
            print("[ProfileViewController] - No profile data available")
            return
        }
        
        nameLabel.text = profile.name
        loginNameLabel.text = profile.loginName
        descriptionLabel.text = profile.bio ?? ""
        
        print("[ProfileViewController] - Updated profile UI for user: \(profile.username)")
    }
    
    private func updateAvatar() {
        guard
            let urlString = profileImageService.avatarURL,
            let url = URL(string: urlString)
        else {
            print("[ProfileViewController] - No avatar URL available")
            return
        }
        
        print("[ProfileViewController] - Loading avatar from URL: \(url)")
        
        // Use Kingfisher to load the avatar image
        profileAvatarImage.kf.indicatorType = .activity
        profileAvatarImage.kf.setImage(
            with: url,
            placeholder: UIImage(named: "profile_icon_default"),
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage,
                .processor(DownsamplingImageProcessor(size: CGSize(width: 140, height: 140))),
                .scaleFactor(UIScreen.main.scale),
                .cacheSerializer(FormatIndicatedCacheSerializer.png)
            ]
        ) { result in
            switch result {
            case .success(let value):
                print("[ProfileViewController] - Avatar loaded successfully from: \(value.source)")
            case .failure(let error):
                print("[ProfileViewController] - Failed to load avatar: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Actions
    @objc private func didTapLogoutButton() {
        // TODO: Implement logout functionality in future sprint
        print("[ProfileViewController] - Logout button tapped")
    }
}
