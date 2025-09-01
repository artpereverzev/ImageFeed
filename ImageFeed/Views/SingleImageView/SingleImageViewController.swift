//
//  SingleImageViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 24.06.2025.
//
import UIKit
import Kingfisher

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
        return imageView
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "sharing_button"), for: .normal)
        button.addTarget(self, action: #selector(didTapShareButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "nav_back_button"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "BackButton"
        return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    var imageURL: URL? {
        didSet {
            guard isViewLoaded else { return }
            loadImage()
        }
    }
    
    // For backward compatibility with local images
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            if let image = image {
                imageView.image = image
                configureImageForCurrentSize()
                shareButton.isEnabled = true
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        
        if let _ = imageURL {
            loadImage()
        } else if let _ = image {
            configureImageForCurrentSize()
        }
    }
    
    // MARK: - Private Methods
    private func setupViews() {
        view.backgroundColor = .ypBlack
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(shareButton)
        view.addSubview(backButton)
        view.addSubview(activityIndicator)
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
            backButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadImage() {
        guard let imageURL = imageURL else { return }
        
        activityIndicator.startAnimating()
        shareButton.isEnabled = false
        
        imageView.kf.setImage(
            with: imageURL,
            placeholder: nil,
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage,
                .onFailureImage(UIImage(named: "Stub"))
            ]
        ) { [weak self] result in
            self?.activityIndicator.stopAnimating()
            
            switch result {
            case .success(_):
                self?.shareButton.isEnabled = true
                self?.configureImageForCurrentSize()
            case .failure(let error):
                print("[SingleImageViewController] - Failed to load image: \(error)")
                self?.showError()
            }
        }
    }
    
    private func configureImageForCurrentSize() {
        guard let image = imageView.image else { return }
        
        let imageSize = image.size
        let scrollViewSize = scrollView.bounds.size
        
        guard scrollViewSize.width > 0 && scrollViewSize.height > 0 else { return }
        
        // Calculate scale ratio for aspect fill
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
        
        scrollView.contentSize = imageView.frame.size
        scrollView.zoomScale = 1.0
        
        // Center the image
        let offsetX = max((imageView.frame.width - scrollView.frame.width) / 2, 0)
        let offsetY = max((imageView.frame.height - scrollView.frame.height) / 2, 0)
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
    }
    
    private func showError() {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Что-то пошло не так. Попробовать ещё раз?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Не надо", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.loadImage()
        })
        
        present(alert, animated: true)
    }
    
    // Handle layout changes
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if imageView.image != nil {
            configureImageForCurrentSize()
        }
    }
    
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
        dismiss(animated: true)
    }
    
    @objc private func didTapShareButton() {
        guard let image = imageView.image else { return }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension SingleImageViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
