//
//  ImagesListViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 12.06.2025.
//

import UIKit
import Kingfisher

// MARK: - ImagesListViewControllerProtocol
protocol ImagesListViewControllerProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol? { get set }
    func insertRows(at indexes: [Int])
    func updateLikeStatus(at index: Int, isLiked: Bool)
    func showLoading()
    func hideLoading()
    func showLikeError()
}

// MARK: - ImagesListViewController
final class ImagesListViewController: UIViewController & ImagesListViewControllerProtocol {
    
    // MARK: - Constants
    private enum Constants {
        static let contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .ypBlack
        tableView.separatorStyle = .none
        tableView.contentInset = Constants.contentInset
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: - Properties
    var presenter: ImagesListPresenterProtocol?
    
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
        presenter?.viewDidLoad()
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
    
    private func showSingleImage(at indexPath: IndexPath) {
        guard let photo = presenter?.photo(at: indexPath.row) else { return }
        
        let singleImageVC = SingleImageViewController()
        
        if let url = URL(string: photo.largeImageURL) {
            singleImageVC.imageURL = url
        }
        
        singleImageVC.modalPresentationStyle = .fullScreen
        present(singleImageVC, animated: true)
    }
    
    private func configCell(for cell: ImagesListCell, at indexPath: IndexPath) {
        guard let photo = presenter?.photo(at: indexPath.row) else { return }
        
        cell.delegate = self
        cell.tag = photo.id.hashValue
        
        // Set date label
        if let createdAt = photo.createdAt {
            cell.cellDateLabel.text = dateFormatter.string(from: createdAt)
        } else {
            cell.cellDateLabel.text = ""
        }
        
        // Set like button state
        cell.setIsLiked(photo.isLiked)
        
        // Load image using Kingfisher
        if let url = URL(string: photo.thumbImageURL) {
            cell.cellImage.kf.indicatorType = .activity
            
            let currentPhotoId = photo.id.hashValue
            
            cell.cellImage.kf.setImage(
                with: url,
                placeholder: UIImage(named: "Stub"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ],
                completionHandler: { result in
                    guard cell.tag == currentPhotoId else { return }
                    
                    if case .failure(let error) = result {
                        print("[ImagesListViewController] - Failed to load image: \(error)")
                    }
                }
            )
        } else {
            cell.cellImage.image = UIImage(named: "Stub")
        }
    }
    
    // MARK: - ImagesListViewControllerProtocol Methods
    func insertRows(at indexes: [Int]) {
        tableView.performBatchUpdates {
            let indexPaths = indexes.map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
    
    func updateLikeStatus(at index: Int, isLiked: Bool) {
        let indexPath = IndexPath(row: index, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
            cell.setIsLiked(isLiked)
        }
    }
    
    func showLoading() {
        UIBlockingProgressHUD.show()
    }
    
    func hideLoading() {
        UIBlockingProgressHUD.dismiss()
    }
    
    func showLikeError() {
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
        return presenter?.photosCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let imageListCell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath) as? ImagesListCell else {
            fatalError("Unable to dequeue ImagesListCell")
        }
        
        configCell(for: imageListCell, at: indexPath)
        return imageListCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showSingleImage(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return presenter?.calculateHeight(for: indexPath.row, tableWidth: tableView.bounds.width) ?? 200
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Load next page when displaying the last cell
        if indexPath.row == (presenter?.photosCount ?? 0) - 1 {
            presenter?.didScrollToLastCell()
        }
    }
}

// MARK: - ImagesListCellDelegate
extension ImagesListViewController: ImagesListCellDelegate {
    
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        presenter?.didTapLike(at: indexPath.row)
    }
}
