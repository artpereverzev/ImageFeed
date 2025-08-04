//
//  SingleImageViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 24.06.2025.
//
import UIKit

final class SingleImageViewController: UIViewController {
    // MARK: - UI Elements
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 1.25
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = .zero
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        // No translatesAutoresizingMaskIntoConstraints = false here!
        // We use frame-based layout for the imageView inside scrollView
        return imageView
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "sharing_button"), for: .normal)
        button.addTarget(self, action: #selector(didTapShareButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "nav_back_button"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return } // Only configure if view is loaded
            configureInitialImage()
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        configureInitialImage()
    }
    
    // MARK: - Private Methods
    private func setupViews() {
        view.backgroundColor = .ypBlack
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(shareButton)
        view.addSubview(backButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Share Button
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -17),
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Back Button
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 48),
            backButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func configureInitialImage() {
        imageView.image = image
        guard let image = image else { return } // Return if no image
        
        let imageSize = image.size
        let scrollViewSize = scrollView.bounds.size
        
        // Calculate scale ratio for aspect fill (image fills entire screen, may crop)
        let widthRatio = scrollViewSize.width / imageSize.width
        let heightRatio = scrollViewSize.height / imageSize.height
        let scale = max(widthRatio, heightRatio)
        
        // Set imageView frame to scaled size
        imageView.frame = CGRect(
            x: 0,
            y: 0,
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        scrollView.contentSize = imageView.frame.size // Set content size
        scrollView.zoomScale = 1.0 // Reset zoom to default
        
        // Center the image by calculating appropriate offset
        let offsetX = max((imageView.frame.width - scrollView.frame.width) / 2, 0)
        let offsetY = max((imageView.frame.height - scrollView.frame.height) / 2, 0)
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
    }
    
    // Handle layout changes (rotation, resize etc.)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Recalculate layout when view changes size
        if let image = image {
            let imageSize = image.size
            let scrollViewSize = scrollView.bounds.size
            
            // Recalculate scale for new size
            let scale = max(scrollViewSize.width / imageSize.width, scrollViewSize.height / imageSize.height)
            
            // Update image view size
            imageView.frame.size = CGSize(
                width: imageSize.width * scale,
                height: imageSize.height * scale
            )
            scrollView.contentSize = imageView.frame.size
            
            // Re-center the image
            let offsetX = max((imageView.frame.width - scrollView.frame.width) / 2, 0)
            let offsetY = max((imageView.frame.height - scrollView.frame.height) / 2, 0)
            scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
        }
    }
    
    // MARK: - Centering
    // Center the image in scroll view
    private func centerImage() {
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame
        
        // Horizontal centering
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        // Vertical centering
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
    
    // MARK: - Actions
    @objc private func didTapBackButton() {
        dismiss(animated: true) // Dismiss the view controller
    }
    
    @objc private func didTapShareButton() {
        guard let image = image else { return }
        
        // Create and present activity view controller for sharing
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension SingleImageViewController: UIScrollViewDelegate {
    
    // Return the view to zoom (our imageView)
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // Center image after zooming
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
