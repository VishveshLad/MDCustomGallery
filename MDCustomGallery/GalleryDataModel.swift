//
//  GalleryDataModel.swift
//  MDCustomGallery
//
//  Created by SOTSYS317 on 20/01/23.
//

import Foundation
import UIKit
import Photos

struct GalleryData {
    var mediaID: Int?
    var thumbNailImage: UIImage?
    var phAssets: PHAsset?
    var videoUrl: URL?
    var galleryType: PHAssetMediaType? // 1 - Image, 2 - Video
    var isSelected = true
    var avaAssets : AVAsset?
    var currentSelectedIndex: Int?
    var maxDuration: Double?
    
    init (mediaID: Int?, phAssets: PHAsset?,thumbNailImage: UIImage?, videoUrl: URL?, galleryType: PHAssetMediaType?, avaAssets : AVAsset?,currentSelectedIndex: Int? = nil, maxDuration: Double?) {
        self.mediaID = mediaID
        self.phAssets = phAssets
        self.thumbNailImage = thumbNailImage
        self.videoUrl = videoUrl
        self.galleryType = galleryType
        self.avaAssets = avaAssets
        self.currentSelectedIndex = currentSelectedIndex
        self.maxDuration = maxDuration
    }
}

