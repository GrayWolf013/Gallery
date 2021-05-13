import UIKit
import Photos

public protocol CartDelegate: class {
    func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool)
    func cart(_ cart: Cart, didRemove image: Image)
    func cartDidReload(_ cart: Cart)
}

/// Cart holds selected images and videos information
public class Cart {
    
    public var images: [Image] = []
    public var video: Video?
    public var currentSize: Double = .zero
    private var byteCountFormatter = ByteCountFormatter()

    private var temporaryImages: [Image] = []
    private var temporaryVideo: Video?

    var delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    // MARK: - Delegate
    
    public func add(delegate: CartDelegate) {
        delegates.add(delegate)
    }
    
    // MARK: - Logic
    
    public func setInitialImages() {
        temporaryVideo = video
        temporaryImages = images
    }
    
    public func resetInitialImages() {
        images = temporaryImages
        video = temporaryVideo
    }
    
    public func add(_ image: Image, newlyTaken: Bool = false) {
        guard !images.contains(image) else { return }
        
        images.append(image)
        handleCurrentSize()

        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cart(self, didAdd: image, newlyTaken: newlyTaken)
        }
    }
    
    public func remove(_ image: Image) {
        guard let index = images.firstIndex(of: image) else { return }
        
        images.remove(at: index)
        handleCurrentSize()

        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cart(self, didRemove: image)
        }
    }
    
    public func remove(with imageID: String) {
        guard let index = images.firstIndex(where: { $0.asset.localIdentifier == imageID }) else { return }
        
        images.remove(at: index)
        handleCurrentSize()

        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cartDidReload(self)
        }
    }
    
    public func reload(_ images: [Image]) {
        self.images = images
        handleCurrentSize()
        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cartDidReload(self)
        }
    }
    
    // MARK: - Reset
    
    public func clear() {
        video = nil
        images.removeAll()
        handleCurrentSize()

        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cartDidReload(self)
        }
    }
    
    public func reset() {
        video = nil
        images.removeAll()
        delegates.removeAllObjects()
        handleCurrentSize()
    }
    
    private func handleCurrentSize() {
        resolveImagesData(images) { [weak self] imagesData in
            guard let self = self else { return }
            self.currentSize = imagesData.reduce(0) {
                $0 + (self.getSize(data: $1) ?? .zero)
            }
            
            print("current images size: \(self.currentSize)")
            EventHub.shared.imageSize?(self.currentSize)
        }
    }
    
    private func getSize(data: Data?) -> Double {
        guard let data = data else { return .zero }
        byteCountFormatter.allowedUnits = [.useMB]
        byteCountFormatter.countStyle = .file
        
        return Double(data.count) / (1024 * 1024)
    }
    
    private func resolveImagesData(_ images: [Image], onCompletion: @escaping ([Data]) -> Void) {
        var dispatchGroup: DispatchGroup? = DispatchGroup()
        var resolvedImagesData: [Data] = []
        
        images.forEach { current in
            dispatchGroup?.enter()
            current.resolve {
                guard let imageData = $0?.jpegData(compressionQuality: 1) else { return }
                resolvedImagesData.append(imageData)
                dispatchGroup?.leave()
            }
        }
        
        dispatchGroup?.notify(queue: .main) {
            onCompletion(resolvedImagesData)
            dispatchGroup = nil
        }
    }
}
