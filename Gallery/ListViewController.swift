//
//  ListViewController.swift
//  Gallery
//
//  Created by Raihana Souleymane on 4/7/17.
//  Copyright © 2017 Raihana Souleymane. All rights reserved.
//


import UIKit
import Photos

class ListViewController: UITableViewController {

    
    var fullGallery: PHFetchResult<PHAsset>!
    var albumCategory: PHFetchResult<PHAssetCollection>!
    var otherApps: PHFetchResult<PHCollection>!
    
    enum SectionNumber: Int {
        case fullGallery = 0
        case albumCategory
        case otherApps
        static let count = 3
    }

    enum SegueIdentifier: String {
        case goToFullGallery
        case goToSpecificAlbum
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fullGalleryOptions = PHFetchOptions()
        fullGalleryOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fullGallery = PHAsset.fetchAssets(with: fullGalleryOptions)
        albumCategory = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        otherApps = PHCollectionList.fetchTopLevelUserCollections(with: nil)

        PHPhotoLibrary.shared().register(self)

    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }


    // MARK: Segues Navigaion

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let vc = segue.destination as? CollectionViewController
            else {
                print("No destination View Controller matching this segue found")
                return
        }
        let cell = sender as! UITableViewCell

        vc.title = cell.textLabel?.text

        switch SegueIdentifier(rawValue: segue.identifier!)! {
            case .goToFullGallery:
                vc.allResult = fullGallery
            case .goToSpecificAlbum:
                let indexPath = tableView.indexPath(for: cell)!
                let collection: PHCollection
                switch SectionNumber(rawValue: indexPath.section)! {
                    case .albumCategory:
                        collection = albumCategory.object(at: indexPath.row)
                    case .otherApps:
                        collection = otherApps.object(at: indexPath.row)
                    default: return
                }
                guard let assetCollection = collection as? PHAssetCollection
                    else { print(" No assetCollection found")
                        return
                         }
                vc.allResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
             
        }
    }

    // MARK: Table View Delegates functions

    override func numberOfSections(in tableView: UITableView) -> Int {
        return SectionNumber.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionNumber(rawValue: section)! {
            case .fullGallery: return 1
            case .albumCategory: return albumCategory.count
            case .otherApps: return otherApps.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SectionNumber(rawValue: indexPath.section)! {
            case .fullGallery:
                let cell = tableView.dequeueReusableCell(withIdentifier: "fullGallery", for: indexPath)
                cell.textLabel!.text = "Full Gallery - (\(fullGallery.count))"
                return cell

            case .albumCategory:
                let cell = tableView.dequeueReusableCell(withIdentifier: "collection", for: indexPath)
                let collection = albumCategory.object(at: indexPath.row)
                cell.textLabel!.text = collection.localizedTitle
                return cell

            case .otherApps:
                let cell = tableView.dequeueReusableCell(withIdentifier: "collection", for: indexPath)
                let collection = otherApps.object(at: indexPath.row)
                cell.textLabel!.text = collection.localizedTitle
                return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Albums per Category"
        }
        if section == 2 {
            return "Albums from other Apps"
        }
       return ""
    }

}

// MARK: PHPhotoLibraryChangeObserver Delegates
extension ListViewController: PHPhotoLibraryChangeObserver {

    func photoLibraryDidChange(_ changeInstance: PHChange) {
//Update the changes such as Album names
        DispatchQueue.main.sync {
        if let changeDetails = changeInstance.changeDetails(for: fullGallery) {
                fullGallery = changeDetails.fetchResultAfterChanges
                //This section doesn't need relaod, it has a static title "Full Gallery"
            }
            if let changeDetails = changeInstance.changeDetails(for: albumCategory) {
                albumCategory = changeDetails.fetchResultAfterChanges
                tableView.reloadSections(IndexSet(integer: SectionNumber.albumCategory.rawValue), with: .automatic)
            }
            if let changeDetails = changeInstance.changeDetails(for: otherApps) {
                otherApps = changeDetails.fetchResultAfterChanges
                tableView.reloadSections(IndexSet(integer: SectionNumber.otherApps.rawValue), with: .automatic)
            }

        }
    }
}

