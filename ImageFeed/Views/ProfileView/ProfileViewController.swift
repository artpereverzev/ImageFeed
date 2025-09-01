//
//  ProfileViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 24.06.2025.
//

import UIKit
import Kingfisher

// MARK: - ProfileViewControllerProtocol
protocol ProfileViewControllerProtocol: AnyObject {
    var presenter: ProfilePresenterProtocol? { get set }
    func updateProfileDetails(name: String, loginName: String, bio: String)
    func updateAvatar(from urlString: String)
    func showLogoutConfirmationAlert()
    func showLoading()
    func hideLoading()
    func switchToSplashScreen()
}

// MARK: - ProfileViewController
final class ProfileViewController: UIViewController & ProfileViewControllerProtocol {
    // MARK: - UI Elements
    private lazy var profileAvatarImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "profile_icon_default")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 35
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
        button.accessibilityIdentifier = "LogoutButton"
        return button
    }()
    
    // MARK: - Properties
    var presenter: ProfilePresenterProtocol?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        setupActions()
        presenter?.viewDidLoad()
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
    
    // MARK: - Actions
    @objc private func didTapLogoutButton() {
        presenter?.didTapLogoutButton()
    }
    
    // MARK: - ProfileViewControllerProtocol Methods
    func updateProfileDetails(name: String, loginName: String, bio: String) {
        nameLabel.text = name
        loginNameLabel.text = loginName
        descriptionLabel.text = bio
    }
    
    func updateAvatar(from urlString: String) {
        guard let url = URL(string: urlString) else {
            print("[ProfileViewController] - Invalid avatar URL")
            return
        }
        
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
                print("[ProfileViewController] - Avatar loaded from: \(value.source)")
            case .failure(let error):
                print("[ProfileViewController] - Failed to load avatar: \(error.localizedDescription)")
            }
        }
    }
    
    func showLogoutConfirmationAlert() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены что хотите выйти?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: "Да",
            style: .default
        ) { [weak self] _ in
            guard let presenter = self?.presenter as? ProfilePresenter else { return }
            presenter.confirmLogout()
        })
        
        alert.addAction(UIAlertAction(
            title: "Нет",
            style: .default,
            handler: nil
        ))
        
        present(alert, animated: true)
    }
    
    func showLoading() {
        UIBlockingProgressHUD.show()
    }
    
    func hideLoading() {
        UIBlockingProgressHUD.dismiss()
    }
    
    func switchToSplashScreen() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            print("[ProfileViewController] - Failed to get key window")
            return
        }
        
        let splashViewController = SplashViewController()
        window.rootViewController = splashViewController
        
        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: nil
        )
        
        print("[ProfileViewController] - Switched to splash screen")
    }
}
