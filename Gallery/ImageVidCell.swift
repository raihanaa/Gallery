//
//  ImageVidCell.swift
//  Gallery
//
//  Created by Raihana Souleymane on 4/7/17.
//  Copyright © 2017 Raihana Souleymane. All rights reserved.
//

import UIKit

class ImageVidCell: UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var livePhotoBadgeImageView: UIImageView!

    var imgVidIdentifier: String!

    var imagePlaceHolder: UIImage! {
        didSet {
            imageView.image = imagePlaceHolder
        }
    }
    var livePhotoBadgeImage: UIImage! {
        didSet {
            livePhotoBadgeImageView.image = livePhotoBadgeImage
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        livePhotoBadgeImageView.image = nil
    }
}
