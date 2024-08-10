//
//  PhotoLibraryService.swift
//  phore
//
//  Created by Zane on 1/23/23.
//

import Foundation
import Photos
import UIKit

struct PHFetchResultCollection: RandomAccessCollection, Equatable {

    typealias Element = PHAsset
    typealias Index = Int

    var fetchResult: PHFetchResult<PHAsset>

    var endIndex: Int { fetchResult.count }
    var startIndex: Int { 0 }

    subscript(position: Int) -> PHAsset {
        fetchResult.object(at: fetchResult.count - position - 1)
    }
}

class PhotoLibraryService: ObservableObject {
    
    typealias PHAssetLocalIdentifier = String
    
    enum AuthorizationError: Error {
        case restrictedAccess
    }
    
    enum QueryError: Error {
        case phAssetNotFound
    }
    
    /// The permission status granted by the user
    /// This property will determine if we need to request
    /// for library access or not
    var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    /// https://stackoverflow.com/a/69755543
    /// A collection that allows subscript support to
    /// PHFetchResult<PHAsset>
    ///
    /// The results property will store all of the photo asset ids
    /// that we requested, and will be used by our views to request
    /// for a copy of the photo itself.
    ///
    /// We don't want to store a copy of the actual photo as it would
    /// cost too much memory, especially if we show the photos in a
    /// grid.
    @Published var results = PHFetchResultCollection(
        fetchResult: .init()
    )
    
    /// The manager that will fetch and cache photos for us
    var imageCachingManager = PHCachingImageManager()
    
    func requestAuthorization(
        handleError: ((AuthorizationError?) -> Void)? = nil
    ) {
        /// This is the code that does the permission requests
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            self?.authorizationStatus = status
            /// We can determine permission granted by the status
            switch status {
            /// Fetch all photos if the user granted us access
            /// This won't be the photos themselves but the
            /// references only.
            case .authorized, .limited:
                self?.fetchAllPhotos()
            
            /// For denied response, we should show an error
            case .denied, .notDetermined, .restricted:
                handleError?(.restrictedAccess)
                
            @unknown default:
                break
            }
        }
    }
    
    /// Function that will tell the image caching manager to fetch
    /// all photos from the user's photo library. We don't want to
    /// include hidden assets for obvious privacy reasons.
    ///
    /// We also need to sort the photos being fetched by the most
    /// recent first, mimicking the behaviour of the Recents album
    /// from the Photos app.
    private func fetchAllPhotos() {
        imageCachingManager.allowsCachingHighQualityImages = false
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = false // dont think this does anything with the new api
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        DispatchQueue.main.async {
            self.results.fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        }
    }
    
    /// Requests an image copy given a photo asset id.
    ///
    /// The image caching manager performs the fetching, and will
    /// cache the photo fetched for later use. Please know that the
    /// cache is temporary – all photos cached will be lost when the
    /// app is terminated.
    func fetchImage(
        byLocalIdentifier localId: PHAssetLocalIdentifier,
        targetSize: CGSize = PHImageManagerMaximumSize,
        contentMode: PHImageContentMode = .default
    ) async throws -> UIImage? {
        let results = PHAsset.fetchAssets(
            withLocalIdentifiers: [localId],
            options: nil
        )
        guard let asset = results.firstObject else {
            throw QueryError.phAssetNotFound
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            /// Use the imageCachingManager to fetch the image
            self?.imageCachingManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options,
                resultHandler: { image, info in
                    /// image is of type UIImage
                    if let error = info?[PHImageErrorKey] as? Error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: image)
                }
            )
        }
    }
    
    func fetchAsset(
        byLocalIdentifier localId: PHAssetLocalIdentifier
    ) async throws -> PHAsset {
        let results = PHAsset.fetchAssets(
            withLocalIdentifiers: [localId],
            options: nil
        )
        guard let asset = results.firstObject else {
            throw QueryError.phAssetNotFound
        }
        return asset
    }
    
    
}
