//
//  ImagesListViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 12.06.2025.
//
import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        static let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        static let defaultRowHeight: CGFloat = 200
    }
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .ypBlack
        tableView.separatorStyle = .none
        tableView.contentInset = Constants.contentInset
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.defaultRowHeight
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: - Properties
    private let imagesListService = ImagesListService.shared
    private var photos: [Photo] = []
    private var imagesListServiceObserver: NSObjectProtocol?
    
    // Date formatter for cell dates
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupNotifications()
        
        // Load first page of photos
        imagesListService.fetchPhotosNextPage()
    }
    
    deinit {
        if let observer = imagesListServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Private Methods
    private func setupViews() {
        view.backgroundColor = .ypBlack
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNotifications() {
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.updateTableViewAnimated()
        }
    }
    
    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newPhotos = imagesListService.photos
        
        // Check if we actually have new photos
        guard newPhotos.count > oldCount else {
            // If count is same or less, just update the array (for like status changes)
            photos = newPhotos
            return
        }
        
        // Update our local array
        photos = newPhotos
        
        // Insert only the new rows
        tableView.performBatchUpdates {
            let indexPaths = (oldCount..<newPhotos.count).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: .automatic)
        } completion: { _ in
            print("[ImagesListViewController] - Inserted \(newPhotos.count - oldCount) new rows, total: \(newPhotos.count)")
        }
    }
    
    // Shows single image screen
    private func showSingleImage(at indexPath: IndexPath) {
        guard indexPath.row < photos.count else { return }
        
        let photo = photos[indexPath.row]
        let singleImageVC = SingleImageViewController()
        
        // Set the image URL for the single image view
        if let url = URL(string: photo.largeImageURL) {
            singleImageVC.imageURL = url
        }
        
        singleImageVC.modalPresentationStyle = .fullScreen
        present(singleImageVC, animated: true)
    }
    
    // Configures cell UI elements with photo data
    private func configCell(for cell: ImagesListCell, with photo: Photo, at indexPath: IndexPath) {
        // Set delegate
        cell.delegate = self
        
        // Set a unique identifier for this cell configuration
        cell.tag = photo.id.hashValue
        
        // Set date label
        if let createdAt = photo.createdAt {
            cell.cellDateLabel.text = dateFormatter.string(from: createdAt)
        } else {
            cell.cellDateLabel.text = ""
        }
        
        // Set like button state
        cell.setIsLiked(photo.isLiked)
        
        // Load image using Kingfisher with activity indicator
        if let url = URL(string: photo.thumbImageURL) {
            cell.cellImage.kf.indicatorType = .activity
            
            // Store the current photo ID to check later
            let currentPhotoId = photo.id.hashValue
            
            cell.cellImage.kf.setImage(
                with: url,
                placeholder: UIImage(named: "Stub"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ],
                completionHandler: { result in
                    // Check if this cell is still showing the same photo
                    guard cell.tag == currentPhotoId else { return }
                    
                    switch result {
                    case .success(_):
                        break
                    case .failure(let error):
                        print("[ImagesListViewController] - Failed to load image for photo \(photo.id): \(error)")
                    }
                }
            )
        } else {
            cell.cellImage.image = UIImage(named: "Stub")
        }
    }
    
    private func showLikeErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось поставить лайк",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let imageListCell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath) as? ImagesListCell else {
            fatalError("Unable to dequeue ImagesListCell")
        }
        
        // Ensure we have a valid photo for this index
        guard indexPath.row < photos.count else {
            return imageListCell
        }
        
        let photo = photos[indexPath.row]
        configCell(for: imageListCell, with: photo, at: indexPath)
        
        return imageListCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showSingleImage(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < photos.count else {
            return Constants.defaultRowHeight
        }
        
        let photo = photos[indexPath.row]
        
        // Calculate scaled height maintaining aspect ratio
        let imageViewWidth = tableView.bounds.width - Constants.imageInsets.left - Constants.imageInsets.right
        let scale = imageViewWidth / photo.size.width
        return photo.size.height * scale + Constants.imageInsets.top + Constants.imageInsets.bottom
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Load next page when displaying the last cell
        if indexPath.row == photos.count - 1 && photos.count > 0 {
            print("[ImagesListViewController] - Last cell displayed (row \(indexPath.row)), loading next page")
            imagesListService.fetchPhotosNextPage()
        }
    }
}

// MARK: - ImagesListCellDelegate
extension ImagesListViewController: ImagesListCellDelegate {
    
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        // Ensure we have a valid photo for this index
        guard indexPath.row < photos.count else { return }
        
        let photo = photos[indexPath.row]
        
        // Show blocking progress HUD to prevent race conditions
        UIBlockingProgressHUD.show()
        
        // Perform like/unlike request
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Dismiss the HUD
                UIBlockingProgressHUD.dismiss()
                
                switch result {
                case .success:
                    // Update local photos array from service
                    self.photos = self.imagesListService.photos
                    
                    // Update the cell's like button if it's still visible
                    if let visibleCell = self.tableView.cellForRow(at: indexPath) as? ImagesListCell {
                        // Get the updated photo
                        let updatedPhoto = self.photos[indexPath.row]
                        visibleCell.setIsLiked(updatedPhoto.isLiked)
                    }
                    
                case .failure(let error):
                    print("[ImagesListViewController] - Failed to change like status: \(error)")
                    self.showLikeErrorAlert()
                }
            }
        }
    }
}
