import UIKit
import Photos

/// Wrap a PHAsset
public class Image: Equatable {
    
    public let asset: PHAsset
    
    // MARK: - Initialization
    
    init(asset: PHAsset) {
        self.asset = asset
    }
}

// MARK: - UIImage

extension Image {
    
    /// Resolve UIImage synchronously
    ///
    /// - Returns: The resolved UIImage, otherwise nil
    public func resolve(completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: getTargetSize(),
            contentMode: .default,
            options: options) { [weak self] (image, _) in
            completion(image)
        }
    }
    
    private func getTargetSize() -> CGSize {
        switch Config.cameraPreset {
        case .low:
            return .init(width: 1280, height: 720)
            
        case .medium:
            return .init(width: 1920, height: 1080)
            
        case .high:
            return .init(width: 3840, height: 2160)
            
        case.original:
            return .init(width: asset.pixelWidth, height: asset.pixelHeight)
        }
    }
    
    /// Resolve an array of Image
    ///
    /// - Parameters:
    ///   - images: The array of Image
    ///   - completion: Called when operations completion
    public static func resolve(images: [Image], completion: @escaping ([UIImage?]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var convertedImages = [Int: UIImage]()
        
        for (index, image) in images.enumerated() {
            dispatchGroup.enter()
            
            image.resolve(completion: { resolvedImage in
                if let resolvedImage = resolvedImage {
                    convertedImages[index] = resolvedImage
                }
                
                dispatchGroup.leave()
            })
        }
        
        dispatchGroup.notify(queue: .main, execute: {
            let sortedImages = convertedImages
                .sorted(by: { $0.key < $1.key })
                .map({ $0.value })
            completion(sortedImages)
        })
    }
}

// MARK: - Equatable

public func == (lhs: Image, rhs: Image) -> Bool {
    return lhs.asset == rhs.asset
}
