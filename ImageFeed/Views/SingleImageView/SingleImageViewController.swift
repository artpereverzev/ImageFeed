//
//  SingleImageViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 24.06.2025.
//
import UIKit

final class SingleImageViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var shareButton: UIButton!
    
    // MARK: - Properties
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return } // Only configure if view is loaded
            configureInitialImage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable automatic content inset adjustment (important for full-screen display)
        scrollView.contentInsetAdjustmentBehavior = .never
        setupScrollView()
        
        configureInitialImage()
    }
    
    // Configure scroll view properties
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 1.25
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = .zero
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
    @IBAction private func didTapBackButton(_ sender: Any) {
        dismiss(animated: true) // Dismiss the view controller
    }
    
    @IBAction private func didTapShareButton(_ sender: Any) {
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
