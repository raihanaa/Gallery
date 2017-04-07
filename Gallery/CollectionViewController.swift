//
//  CollectionViewController.swift
//  Gallery
//
//  Created by Raihana Souleymane on 4/7/17.
//  Copyright © 2017 Raihana Souleymane. All rights reserved.
//


import UIKit
import Photos
import PhotosUI

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class CollectionViewController: UICollectionViewController {

    var allResult: PHFetchResult<PHAsset>!
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var previousPreheatRect = CGRect.zero
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    var cellSize : CGSize = CGSize(width: 0, height: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.shared().register(self)
        
        if allResult == nil {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            allResult = PHAsset.fetchAssets(with: allPhotosOptions)
        }
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
         cellSize = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? ImageVideoDisplayViewController
        else { return }

        let indexPath = collectionView!.indexPath(for: sender as! UICollectionViewCell)!
        destination.asset = allResult.object(at: indexPath.item)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allResult.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = allResult.object(at: indexPath.item)
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageVidCell", for: indexPath) as? ImageVidCell
            else { fatalError() }

        // Set a livePhoto identifier on the cell is picture is a live photo.
        if asset.mediaSubtypes.contains(.photoLive) {
           cell.livePhotoBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
        }
        cell.imgVidIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: cellSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            // set the cell's image only if it's still the same asset.
            if cell.imgVidIdentifier == asset.localIdentifier {
                cell.imagePlaceHolder = image
            }
        })

        return cell

    }

   }

// MARK: PHPhotoLibraryChangeObserver Delegates function
extension CollectionViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {

        guard let changes = changeInstance.changeDetails(for: allResult)
            else { return }

      //Changes on the fectched result may happen at any time, update the main view as following
        DispatchQueue.main.sync {
            allResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                // If we have incremental diffs, animate them in the collection view.
                guard let collectionView = self.collectionView else { return }
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                // Reload the collection
                collectionView!.reloadData()
            }
        }
    }
}

