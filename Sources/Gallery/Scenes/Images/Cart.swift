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

        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cart(self, didAdd: image, newlyTaken: newlyTaken)
        }
    }
    
    public func remove(_ image: Image) {
        guard let index = images.firstIndex(of: image) else { return }
        
        images.remove(at: index)

        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cart(self, didRemove: image)
        }
    }
    
    public func remove(with imageID: String) {
        guard let index = images.firstIndex(where: { $0.asset.localIdentifier == imageID }) else { return }
        
        images.remove(at: index)

        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cartDidReload(self)
        }
    }
    
    public func reload(_ images: [Image]) {
        self.images = images
        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cartDidReload(self)
        }
    }
    
    // MARK: - Reset
    
    public func clear() {
        video = nil
        images.removeAll()

        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cartDidReload(self)
        }
    }
    
    public func reset() {
        video = nil
        images.removeAll()
        delegates.removeAllObjects()
    }
}
