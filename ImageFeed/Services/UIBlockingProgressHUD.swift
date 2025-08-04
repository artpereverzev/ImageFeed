//
//  UIBlockingProgressHUD.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 04.08.2025.
//

import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        // Modern way to get the key window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first { $0.isKeyWindow }
        }
        // Fallback for older iOS versions
        return UIApplication.shared.windows.first { $0.isKeyWindow }
    }
    
    static func show() {
        DispatchQueue.main.async {
            window?.isUserInteractionEnabled = false
            ProgressHUD.animate()
        }
    }
    
    static func dismiss() {
        DispatchQueue.main.async {
            window?.isUserInteractionEnabled = true
            ProgressHUD.dismiss()
        }
    }
}
