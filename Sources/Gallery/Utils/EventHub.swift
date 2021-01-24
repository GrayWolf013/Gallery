import Foundation

class EventHub {
    
    typealias Action<C> = (C) -> Void
    
    static let shared = EventHub()
    
    // MARK: Initialization
    
    init() {}
    
    var close: Action<Void>?
    var doneWithImages: Action<Void>?
    var doneWithVideos: Action<Void>?
    var stackViewTouched: Action<Void>?
    var previewImage: Action<Image>?
    var requestScrollToGallery: Action<Void>?
    var imageCaptured: Action<Void>?
    var imageSize: Action<Double>?
}
