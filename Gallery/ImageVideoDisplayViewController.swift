//
//  ImageVideoDisplayViewController.swift
//  Gallery
//
//  Created by Raihana Souleymane on 4/7/17.
//  Copyright © 2017 Raihana Souleymane. All rights reserved.
//

import UIKit
import Photos
import PhotosUI


class ImageVideoDisplayViewController: UIViewController {

    @IBOutlet var playButton: UIBarButtonItem!
    @IBOutlet var space: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var livePhotoView: PHLivePhotoView!
 
    fileprivate var myVideoPlayer: AVPlayerLayer!
    fileprivate var livePhotoIsPlaying = false
    var asset: PHAsset!


    override func viewDidLoad() {
        super.viewDidLoad()
        livePhotoView.delegate = self
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
// Add playButton on the toolbar if the asset is type of video
        if asset.mediaType == .video {
                toolbarItems = [space, playButton, space]
                navigationController?.isToolbarHidden = false
            }
// Adjust the view layout then request an image.
        view.layoutIfNeeded()
        updateImage()
    }

    @IBAction func play(_ sender: AnyObject) {
        if myVideoPlayer != nil {
            myVideoPlayer.player!.play()
        } else {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .automatic
            options.progressHandler = { progress, _, _, _ in
            }
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options, resultHandler: { playerItem, info in
                DispatchQueue.main.sync {
                    guard self.myVideoPlayer == nil else { return }
                    let player = AVPlayer(playerItem: playerItem)
                    let playerLayer = AVPlayerLayer(player: player)
                    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                    playerLayer.frame = self.view.layer.bounds
                    self.view.layer.addSublayer(playerLayer)
                    player.play()

                    self.myVideoPlayer = playerLayer
                }
            })
        }
    }

    // MARK:  Image Update and display

    func updateImage() {
        if asset.mediaSubtypes.contains(.photoLive) {
            updateLivePhoto()
        } else {
            updateSimpleImage()
        }
    }

    func updateLivePhoto() {
        // Set the options for live photo.
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
        }

        // Get the live photo from PHImageManager.
        PHImageManager.default().requestLivePhoto(for: asset, targetSize:
                                                           CGSize(width: imageView.bounds.width * (UIScreen.main.scale),
                                                                  height: imageView.bounds.height * (UIScreen.main.scale)),
                                                                  contentMode: .aspectFit,
                                                                  options: options, resultHandler: { livePhoto, info in
            //checkif live photo not null
            guard let livePhoto = livePhoto else { return }
            self.imageView.isHidden = true
            self.livePhotoView.isHidden = false
            self.livePhotoView.livePhoto = livePhoto
                                                                    
            // Check if live photo playing , then set playback
            if !self.livePhotoIsPlaying {
                self.livePhotoIsPlaying = true
                self.livePhotoView.startPlayback(with: .hint)
            }
        })
    }

    func updateSimpleImage() {
        // Prepare the options to pass when fetching the (photo, or video preview) image.
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
        }

        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: imageView.bounds.width * (UIScreen.main.scale),
                                                                             height: imageView.bounds.height * (UIScreen.main.scale)),
                                                                           contentMode: .aspectFit,
                                                                           options: options, resultHandler: { image, _ in
            // Check if image not null
            guard let image = image else { return }
            self.livePhotoView.isHidden = true
            self.imageView.isHidden = false
            self.imageView.image = image
        })
    }

   

}

// MARK: PHPhotoLibraryChangeObserver and PHLivePhotoViewDelegate
extension ImageVideoDisplayViewController: PHPhotoLibraryChangeObserver, PHLivePhotoViewDelegate {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        //Changes on the displayed object may happen at any time, update the main view as following
        DispatchQueue.main.sync {
            guard let details = changeInstance.changeDetails(for: asset) else { return }
            asset = details.objectAfterChanges as! PHAsset

            if details.assetContentChanged {
                updateImage()
                myVideoPlayer?.removeFromSuperlayer()
                myVideoPlayer = nil
            }
        }
    }
   func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        livePhotoIsPlaying = (playbackStyle == .hint)
    }

    func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        livePhotoIsPlaying = (playbackStyle == .hint)
    }
}
