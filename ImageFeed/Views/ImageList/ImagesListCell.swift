//
//  ImagesListCell.swift
//  ImageFeed
//
//  Created by Artem Pereverzev on 18.06.2025.
//
import UIKit

final class ImagesListCell: UITableViewCell {
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var cellLikeButton: UIButton!
    @IBOutlet var cellDateLabel: UILabel!
    
    static let reuseIdentifier = "ImagesListCell"
}
