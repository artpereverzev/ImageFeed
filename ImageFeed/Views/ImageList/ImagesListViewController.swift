//
//  ViewController.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 12.06.2025.
//
import UIKit

final class ImagesListViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        static let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        static let defaultRowHeight: CGFloat = 200
        static let showSingleImageSegueIdentifier = "ShowSingleImage"
    }
    
    // MARK: - IBOutlets
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - Properties
    // Array of image names (using numbers 0-19 as strings)
    private let photosName: [String] = Array(0..<20).map{ "\($0)" }
    
    // Date formatter for cell dates (lazy to defer initialization)
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long  // Full date style (e.g., "June 12, 2025")
        formatter.timeStyle = .none  // No time display
        return formatter
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSingleImage" {
            guard
                let singleImageVC = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid configuration")
                return
            }
            
            let image = UIImage(named: photosName[indexPath.row])
            singleImageVC.image = image
        }
    }

    // MARK: - Private Methods
    // Configures table view properties and delegates
    private func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.defaultRowHeight
        tableView.contentInset = Constants.contentInset
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // Returns formatted current date string
    private func formattedDate() -> String {
        return dateFormatter.string(from: Date())
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate, UITableViewDataSource {
    
    // Returns number of rows equal to photos count
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photosName.count
    }
    
    // Configures and returns a cell for specific index path
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue reusable cell with safety checks
        guard let imageListCell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath) as? ImagesListCell else {
            fatalError("Unable to dequeue ImagesListCell")  // Crash explicitly if configuration is wrong
        }
        
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowSingleImage", sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        // Load image or return default height if failed
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return Constants.defaultRowHeight
        }
        
        // Calculate scaled height maintaining aspect ratio
        let imageViewWidth = tableView.bounds.width - Constants.imageInsets.left - Constants.imageInsets.right
        let scale = imageViewWidth / image.size.width
        return image.size.height * scale + Constants.imageInsets.top + Constants.imageInsets.bottom
    }
    
    // Configures cell UI elements with data
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        
        cell.cellImage.image = UIImage(named: photosName[indexPath.row])
        cell.cellDateLabel.text = formattedDate()
        
        let likeImageName = indexPath.row % 2 == 0 ? "LikeButtonActive" : "LikeButtonNoActive"
        cell.cellLikeButton.setImage(UIImage(named: likeImageName), for: .normal)
    }
}

