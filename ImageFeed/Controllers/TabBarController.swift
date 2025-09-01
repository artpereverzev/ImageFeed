//
//  TabBarController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 01.09.2025
//

import UIKit

final class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        tabBar.backgroundColor = .ypBlack
        tabBar.barTintColor = .ypBlack
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = .gray
        
        // Remove the default gray line
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .ypBlack
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    private func setupViewControllers() {
        // Create ImagesListViewController with Presenter
        let imagesListVC = ImagesListViewController()
        let imagesListPresenter = ImagesListPresenter()
        imagesListVC.presenter = imagesListPresenter
        imagesListPresenter.view = imagesListVC
        
        imagesListVC.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil
        )
        imagesListVC.tabBarItem.accessibilityIdentifier = "FeedTab"
        
        // Create ProfileViewController with Presenter
        let profileVC = ProfileViewController()
        let profilePresenter = ProfilePresenter()
        profileVC.presenter = profilePresenter
        profilePresenter.view = profileVC
        
        profileVC.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
        profileVC.tabBarItem.accessibilityIdentifier = "ProfileTab"
        
        viewControllers = [imagesListVC, profileVC]
    }
}
