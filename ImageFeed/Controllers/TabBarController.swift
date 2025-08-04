//
//  TabBarController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 04.08.2025.
//
import UIKit

final class TabBarController: UITabBarController {
    
    // IMPORTANT NOTE FOR REVIEWER: awakeFromNib() is only called when an object is loaded from a nib/storyboard file (as I can understand).
    // Since i'm creating everything programmatically, this method might not be called,
    // so because of that I decided to do everything in viewDidLoad.
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
        let imagesListViewController = ImagesListViewController()
        imagesListViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil
        )
        
        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
        
        self.viewControllers = [imagesListViewController, profileViewController]
    }
}
