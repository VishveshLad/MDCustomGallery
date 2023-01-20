//
//  ViewController.swift
//  MDCustomGallery
//

import UIKit
import Photos

class ViewController: UIViewController {
    
    fileprivate var collectionView: UICollectionView!
    fileprivate var collectionViewLayout: UICollectionViewFlowLayout!
    fileprivate var assets: PHFetchResult<PHAsset>?
    fileprivate var sideSize: CGFloat!
    var mediaType: PHAssetMediaType = .image
    
    private let titleLable: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.text = "Gallery"
        return label
    }()
    
    var arrGalleryDataModel : [GalleryData] = []
    var width = CGFloat()
    
    //MARK:- View Controller life cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLable.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.titleLable)
        
        self.titleLable.topAnchor.constraint(equalTo: view.topAnchor , constant: 35 ).isActive = true
        self.titleLable.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        self.titleLable.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        //SET UP VIEW
        self.setupView()
        self.getAssetsData()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    public func getAssetsData(){
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            reloadAssets()
        } else {
            PHPhotoLibrary.requestAuthorization({ [weak self] (status: PHAuthorizationStatus) -> Void in
                guard  let `self` = self else { return }
                if status == .authorized {
                    self.reloadAssets()
                } else {
                    self.showNeedAccessMessage()
                }
            })
        }
    }

    public func showNeedAccessMessage() {
        let alert = UIAlertController(title: "Image picker", message: "App need get access to photos", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }else{
                    UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    public func reloadAssets() {
        DispatchQueue.main.async {
            self.width  = self.view.bounds.width / 2

            self.assets = nil
            self.arrGalleryDataModel.removeAll()
            self.collectionView.reloadData()
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            self.assets = PHAsset.fetchAssets(with: fetchOptions)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                self.getAllGalleryData()
            })
        }
    }
    
    public func getAllGalleryData() {
        for i in 0..<(assets?.count ?? 0) {
            let asset = assets?.object(at: i)
            let phAssetsData = GalleryData(mediaID:i, phAssets: asset,thumbNailImage: nil, videoUrl: nil, galleryType: asset?.mediaType, avaAssets: nil, maxDuration: nil)
            self.arrGalleryDataModel.append(phAssetsData)
        }
        
        for (index) in 0..<self.arrGalleryDataModel.count {
            autoreleasepool {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .exact
                options.isSynchronous = true
                
                guard let asset = self.arrGalleryDataModel[index].phAssets else {return}
                
                PHCachingImageManager.default().requestImage(for: asset , targetSize: CGSize(width: self.width, height: 0.90 * self.width), contentMode: .aspectFit, options: options) { [weak self] (image, info) in
                    guard let `self` = self else { return }
                    
                    if asset.mediaType == .image { // Image
                        self.arrGalleryDataModel[index].thumbNailImage = image
                        self.arrGalleryDataModel[index].galleryType = .image
                    } else if asset.mediaType == .video { // Video
                        let requestOptions = PHVideoRequestOptions()
                        requestOptions.isNetworkAccessAllowed = true
                        requestOptions.version = .original
                        requestOptions.deliveryMode = .mediumQualityFormat
                        
                        PHImageManager.default().requestAVAsset(forVideo: asset , options: requestOptions) { [weak self] (assets, audioMix, info) in
                            guard let `self` = self else { return }
                            let avAsstes = assets as? AVURLAsset
                            self.arrGalleryDataModel[index].galleryType = .video
                            self.arrGalleryDataModel[index].thumbNailImage = image
                            self.arrGalleryDataModel[index].avaAssets = assets
                            self.arrGalleryDataModel[index].videoUrl = avAsstes?.url
                            self.arrGalleryDataModel[index].maxDuration = assets?.duration.seconds
                            
                        }
                    }
                }
            }
        }
       
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    public func setupView(){
        PHPhotoLibrary.shared().register(self)
        
        self.collectionViewLayout = UICollectionViewFlowLayout()
        self.sideSize = ((self.view.bounds.width - 4) / 3)
        self.collectionViewLayout.itemSize = CGSize(width: self.sideSize, height: self.sideSize)
        self.collectionViewLayout.minimumLineSpacing = 2
        self.collectionViewLayout.minimumInteritemSpacing = 2

        self.collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: collectionViewLayout)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.collectionView)
      
        self.collectionView.topAnchor.constraint(equalTo: self.titleLable.bottomAnchor , constant: 10 ).isActive = true
        self.collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        self.collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        self.collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  
        self.collectionView.allowsMultipleSelection = true
        self.collectionView.register(AllMediaPickerCell.self, forCellWithReuseIdentifier: "AllMediaPickerCell")
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = .white
    }
    
    public func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
 }

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrGalleryDataModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AllMediaPickerCell", for: indexPath) as! AllMediaPickerCell
        let objPHAsset = self.arrGalleryDataModel[indexPath.row]
        
        cell.lblInfo.text = stringFromTimeInterval(interval: objPHAsset.maxDuration ?? 0.0)
        cell.lblInfo.isHidden = objPHAsset.galleryType == .video ? false : true
        cell.playImageView.isHidden = objPHAsset.galleryType == .video ? false : true
        cell.image = objPHAsset.thumbNailImage

        return cell
    }
}

extension ViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let _fetchResult = self.assets, let resultDetailChanges = changeInstance.changeDetails(for: _fetchResult) {
            let insertedObjects = resultDetailChanges.insertedObjects
            let removedObjects = resultDetailChanges.removedObjects
            let changedObjects = resultDetailChanges.changedObjects.filter( {
                return changeInstance.changeDetails(for: $0)?.assetContentChanged == true
            })
            if resultDetailChanges.hasIncrementalChanges && (insertedObjects.count > 0 || removedObjects.count > 0 || changedObjects.count > 0){
                DispatchQueue.main.async {
                    self.reloadAssets()
                }
            }
        }
    }
}


public class AllMediaPickerCell: UICollectionViewCell {

    var imageView: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        return img
    }()
    
    var playImageView: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        return img
    }()
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }

    var lblInfo: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.boldSystemFont(ofSize: 12)
        lbl.textColor = .white
        lbl.textAlignment = .right
        lbl.clipsToBounds = true
        return lbl
    }()

    public override init(frame: CGRect) {
        super.init(frame: .zero)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.lblInfo.translatesAutoresizingMaskIntoConstraints = false
                
        self.playImageView.image = UIImage(named: "icon-play-video")
        
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.lblInfo)
        self.contentView.addSubview(playImageView)
        
        // Set Image View
        
        self.playImageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -10).isActive = true
        self.playImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -8).isActive = true
        self.playImageView.heightAnchor.constraint(equalToConstant: 15).isActive = true
        self.playImageView.widthAnchor.constraint(equalToConstant: 15).isActive = true
        self.playImageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.imageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
        self.imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        self.imageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set Info Label
        self.lblInfo.rightAnchor.constraint(equalTo: self.playImageView.leftAnchor, constant: -5).isActive = true
        self.lblInfo.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -8).isActive = true
        self.lblInfo.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.lblInfo.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

