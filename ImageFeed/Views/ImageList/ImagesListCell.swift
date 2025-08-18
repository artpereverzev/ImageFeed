//
//  ImagesListCell.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 18.06.2025.
//
import UIKit
import Kingfisher

// MARK: - Delegate Protocol
protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    // MARK: - UI Elements
    lazy var cellImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var cellLikeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(likeButtonClicked), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var cellDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    static let reuseIdentifier = "ImagesListCell"
    weak var delegate: ImagesListCellDelegate?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Cancel any ongoing image download
        cellImage.kf.cancelDownloadTask()
        
        // Reset to placeholder
        cellImage.image = UIImage(named: "Stub")
        
        // Reset labels
        cellDateLabel.text = ""
        
        // Reset like button
        cellLikeButton.setImage(nil, for: .normal)
        
        // Clear delegate to prevent retain cycles
        delegate = nil
    }
    
    // MARK: - Public Methods
    func setIsLiked(_ isLiked: Bool) {
        let likeImageName = isLiked ? "LikeButtonActive" : "LikeButtonNoActive"
        cellLikeButton.setImage(UIImage(named: likeImageName), for: .normal)
        
        // Add a little animation for feedback
        UIView.animate(withDuration: 0.3, animations: {
            self.cellLikeButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.cellLikeButton.transform = CGAffineTransform.identity
            }
        }
    }
    
    // MARK: - Actions
    @objc private func likeButtonClicked() {
        delegate?.imageListCellDidTapLike(self)
    }
    
    // MARK: - Private Methods
    private func setupCell() {
        backgroundColor = .ypBlack
        contentView.backgroundColor = .ypBlack
        selectionStyle = .none
    }
    
    private func setupViews() {
        contentView.addSubview(cellImage)
        contentView.addSubview(cellDateLabel)
        contentView.addSubview(cellLikeButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Cell Image
            cellImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cellImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cellImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Date Label
            cellDateLabel.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor, constant: 8),
            cellDateLabel.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor, constant: -8),
            cellDateLabel.trailingAnchor.constraint(lessThanOrEqualTo: cellImage.trailingAnchor, constant: -8),
            
            // Like Button
            cellLikeButton.topAnchor.constraint(equalTo: cellImage.topAnchor),
            cellLikeButton.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            cellLikeButton.widthAnchor.constraint(equalToConstant: 44),
            cellLikeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
